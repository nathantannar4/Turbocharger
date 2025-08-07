//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// Redacts content and overlays a shimmering effect when `Value` is `nil`
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
@frozen
public struct ShimmerAdapter<Value, Content: View>: View {

    public var content: Content
    public var isActive: Bool
    public var animation: Animation?

    @inlinable
    public init(
        _ value: Optional<Value>,
        animation: Animation? = .linear(duration: 0.3),
        _ content: (Optional<Value>) -> Content
    ) {
        self.content = content(value)
        self.isActive = value == nil
        self.animation = animation
    }

    public var body: some View {
        content
            .shimmer(isActive: isActive, animation: animation)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
extension View {
    /// Redacts content and overlays a shimmering effect
    public func shimmer(
        isActive: Bool = true,
        animation: Animation? = .linear(duration: 0.3)
    ) -> some View {
        modifier(ShimmerModifier(isActive: isActive, animation: animation))
    }
}

/// A modifier that redacts content and overlays a shimmering effect.
///
/// All active shimmer effects are synchronized to the same clock.
///
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
public struct ShimmerModifier: ViewModifier {
    var isActive: Bool
    var animation: Animation?

    enum ShimmerState {
        case inactive
        case transitioning(DispatchWorkItem?)
        case shimmering

        var completion: DispatchWorkItem? {
            if case .transitioning(let item) = self {
                return item
            }
            return nil
        }

        var isActive: Bool {
            switch self {
            case .inactive:
                return false
            case .transitioning, .shimmering:
                return true
            }
        }
    }

    @State var state: ShimmerState

    public init(isActive: Bool, animation: Animation? = .linear(duration: 0.3)) {
        self.isActive = isActive
        self.animation = animation
        self._state = State(initialValue: isActive ? .shimmering : .inactive)
    }

    public func body(content: Content) -> some View {
        content
            .transformEnvironment(\.self) { environment in
                if state.isActive {
                    environment.isEnabled = false
                    environment.redactionReasons.insert(.placeholder)
                }
                if isActive {
                    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                        environment.contentTransition = .identity
                    }
                }
            }
            .mask(
                mask
                    .animation(animation, value: state.isActive)
            )
            .onChange(of: isActive) { [oldState = state] newValue in
                switch oldState {
                case .inactive:
                    state = newValue ? .shimmering : .inactive

                case .transitioning(let completion):
                    if newValue {
                        completion?.cancel()
                        state = .shimmering
                    }
                case .shimmering:
                    if !newValue {
                        let duration = (animation?.duration(defaultDuration: 0.3) ?? 0) / 2
                        if duration > 0 {
                            let completion = DispatchWorkItem {
                                var transaction = Transaction(animation: animation?.speed(2))
                                transaction.disablesAnimations = true
                                withTransaction(transaction) {
                                    state = .inactive
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: completion)
                            state = .transitioning(completion)
                        } else {
                            state = .inactive
                        }
                    }
                }
            }
    }

    @ViewBuilder
    private var mask: some View {
        switch state {
        case .inactive:
            Rectangle()
                .scale(1000)
                .ignoresSafeArea()
        case .transitioning, .shimmering:
            GradientMask()
        }
    }

    private struct GradientMask: View {
        @ObservedObject var clock = ShimmerClock.shared

        var body: some View {
            PhasedLinearGradient(
                phase: clock.phase
            )
            .onAppear { clock.register() }
            .onDisappear { clock.unregister() }
        }

        struct PhasedLinearGradient: View {
            var phase: CGFloat

            var body: some View {
                LinearGradient(
                    gradient:
                        Gradient(stops: [
                            .init(color: Color.black.opacity(0.3), location: phase * 2 - 1),
                            .init(color: Color.black, location: phase * 2 - 0.5),
                            .init(color: Color.black.opacity(0.3), location: phase * 2)
                        ])
                    ,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .animation(.linear(duration: 1 / 60), value: phase)
            }
        }
    }
}

private class ShimmerClock: ObservableObject {
    @Published var phase: CGFloat = 0

    private let duration: Double = 1.25

    private var registered: UInt = 0
    #if os(iOS)
    private var displayLink: CADisplayLink?
    #endif

    #if os(macOS)
    private var timer: Timer?
    #endif

    nonisolated(unsafe) static let shared = ShimmerClock()
    private init() {
    }

    deinit {
        #if os(iOS)
        displayLink?.invalidate()
        #endif

        #if os(macOS)
        timer?.invalidate()
        #endif
    }

    #if os(iOS)
    @objc
    private func onClockTick(displayLink: CADisplayLink) {
        let offset = CGFloat((displayLink.targetTimestamp - displayLink.timestamp) / duration)
        onClockTick(offset: offset)
    }
    #endif

    #if os(macOS)
    @objc
    private func onClockTick(timer: Timer) {
        let offset = CGFloat(timer.timeInterval / duration)
        onClockTick(offset: offset)
    }
    #endif

    private func onClockTick(offset: CGFloat) {
        if phase >= 1 {
            phase = 0
        } else {
            phase = min(phase + offset, 1)
        }
    }

    func register() {
        if registered == 0 {
            registered += 1
            #if os(iOS)
            if let displayLink = displayLink {
                displayLink.isPaused = false
            } else {
                let displayLink = CADisplayLink(
                    target: self,
                    selector: #selector(onClockTick(displayLink:))
                )
                if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
                    displayLink.preferredFrameRateRange = .init(
                        minimum: 24,
                        maximum: 60
                    )
                }
                displayLink.add(to: .current, forMode: .common)
                self.displayLink = displayLink
            }
            #endif

            #if os(macOS)
            if let timer = timer, timer.isValid {
            } else {
                let timer = Timer(
                    fireAt: Date(),
                    interval: 1 / 60,
                    target: self,
                    selector: #selector(onClockTick(timer:)),
                    userInfo: nil,
                    repeats: true
                )
                RunLoop.current.add(timer, forMode: .common)
                self.timer = timer
            }
            #endif
        } else {
            registered += 1
        }
    }

    func unregister() {
        if registered == 1 {
            registered -= 1
            phase = 0
            #if os(iOS)
            displayLink?.isPaused = true
            #endif

            #if os(macOS)
            timer?.invalidate()
            #endif
        } else if registered > 1 {
            registered -= 1
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
struct ShimmerModifier_Previews: PreviewProvider {
    struct Preview: View {
        @State var isActive = true

        var body: some View {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text(verbatim: isActive ? "Placeholder" : "Line 1, Line 2, Line 3")
                        .border(Color.red)

                    HStack {
                        Text(verbatim: isActive ? "Placeholder" : "Line 1, Line 2, Line 3")
                            .border(Color.red)
                            .shimmer(isActive: isActive)

                        Text("Trailing")
                    }

                    HStack {
                        Text(verbatim: isActive ? "Placeholder" : "Line 1, Line 2, Line 3")
                            .shimmer(isActive: isActive)

                        Text("Trailing")
                    }

                    HStack {
                        Text(verbatim: isActive ? "Placeholder" : "Line 1")
                            .border(Color.red)

                        Text("Trailing")
                    }

                    HStack {
                        Text(verbatim: isActive ? "Placeholder" : "Line 1")
                            .border(Color.red)
                            .shimmer(isActive: isActive)

                        Text("Trailing")
                    }

                    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                        HStack {
                            Text(verbatim: isActive ? "123" : "456")
                                .shimmer(isActive: isActive)
                                .contentTransition(.numericText())

                            Text("Trailing")
                        }
                    }
                }

                HStack {
                    Text(isActive.description)

                    Button {
                        isActive.toggle()
                    } label: {
                        Text("Toggle")
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation {
                            isActive.toggle()
                        }
                    } label: {
                        Text("Toggle (Animated)")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    static var previews: some View {
        VStack {
            Preview()
        }
    }
}
