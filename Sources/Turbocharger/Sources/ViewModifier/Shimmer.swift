//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
extension View {
    /// Redacts content and overlays a shimmering effect
    public func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}

/// A modifier that redacts content and overlays a shimmering effect.
///
/// All active shimmer effects are synchronized to the same clock.
///
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
public struct ShimmerModifier: ViewModifier {
    var isActive: Bool

    enum ShimmerState: Equatable {
        case inactive
        case transitioning(DispatchWorkItem?)
        case shimmering

        var completion: DispatchWorkItem? {
            if case .transitioning(let item) = self {
                return item
            }
            return nil
        }

        static func == (
            lhs: ShimmerModifier.ShimmerState,
            rhs: ShimmerModifier.ShimmerState
        ) -> Bool {
            switch (lhs, rhs) {
            case (.inactive, .inactive), (.shimmering, .shimmering):
                return true
            case (.transitioning(let lhs), .transitioning(let rhs)):
                return lhs === rhs
            default:
                return false
            }
        }
    }

    @State var state: ShimmerState

    public init(isActive: Bool) {
        self.isActive = isActive
        self._state = State(initialValue: isActive ? .transitioning(nil) : .inactive)
    }

    public func body(content: Content) -> some View {
        content
            .disabled(state != .inactive)
            .redacted(reason: state != .inactive ? .placeholder : [])
            .animation(nil, value: state)
            .mask(mask)
            .animation(.linear(duration: 0.3), value: state)
            .onAppearAndChange(of: isActive) { [oldState = state] newValue in
                switch oldState {
                case .inactive:
                    state = newValue ? .transitioning(nil) : .inactive
                case .transitioning(let completion):
                    if newValue {
                        completion?.cancel()
                        state = .shimmering
                    }
                case .shimmering:
                    if !newValue {
                        let completion = DispatchWorkItem {
                            var transaction = Transaction(animation: nil)
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                state = .inactive
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: completion)
                        state = .transitioning(completion)
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
                .onAppear {
                    state = .shimmering
                }
        }
    }

    private struct GradientMask: VersionedView {
        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        var v3Body: some View {
            _V3Body(date: .now)
        }

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        private struct _V3Body: View {
            @State var date: Date

            @Environment(\.calendar) var calendar

            var body: some View {
                TimelineView(
                    .animation(minimumInterval: 1 / 60, paused: false)
                ) { context in
                    let phase = CGFloat(calendar.component(.nanosecond, from: context.date)) / pow(10, 9)
                    PhasedLinearGradient(
                        phase: phase
                    )
                }
            }
        }

        var v2Body: some View {
            _V2Body()
        }

        private struct _V2Body: View {
            @ObservedObject var clock = ShimmerClock.shared

            var body: some View {
                PhasedLinearGradient(
                    phase: clock.phase
                )
                .onAppear { clock.register() }
                .onDisappear { clock.unregister() }
            }
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
            }
        }
    }
}

private class ShimmerClock: ObservableObject {
    @Published var phase: CGFloat = 0

    private let duration: Double = 1.25

    private var registered: UInt = 0
    #if os(iOS)
    private weak var displayLink: CADisplayLink?
    #endif

    #if os(macOS)
    private var timer: Timer?
    #endif

    static let shared = ShimmerClock()
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
        if phase >= 1 {
            phase = 0
        } else {
            phase += offset
        }
    }
    #endif

    #if os(macOS)
    @objc
    private func onClockTick(timer: Timer) {
        let offset = CGFloat(timer.timeInterval / duration)
        if phase >= 1 {
            phase = 0
        } else {
            phase += offset
        }
    }
    #endif


    func register() {
        if registered == 0 {
            registered += 1
            #if os(iOS)
            if let displayLink = displayLink {
                displayLink.isPaused = false
            } else {
                let displayLink = CADisplayLink(target: self, selector: #selector(onClockTick(displayLink:)))
                if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
                    displayLink.preferredFrameRateRange = .init(minimum: 24, maximum: 60)
                }
                displayLink.add(to: .current, forMode: .common)
                self.displayLink = displayLink
            }
            #endif

            #if os(macOS)
            if let timer = timer, timer.isValid {
            } else {
                let timer = Timer(fireAt: Date(), interval: 1 / 30, target: self, selector: #selector(onClockTick(timer:)), userInfo: nil, repeats: true)
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
            VStack {
                HStack {
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

                VStack(alignment: .center) {
                    Text(verbatim: isActive ? "Placeholder" : "Line 1, Line 2, Line 3")
                        .shimmer(isActive: isActive)

                    Text(verbatim: isActive ? "Placeholder" : "Line 1, Line 2, Line 3")
                        .shimmer(isActive: isActive)

                    Text(verbatim: isActive ? "Placeholder" : "Line 1")
                        .shimmer(isActive: isActive)
                }
            }
        }
    }

    static var previews: some View {
        VStack {
            Preview()
        }
    }
}
