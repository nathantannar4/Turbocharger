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
    public var animation: ShimmerAnimation

    @inlinable
    public init(
        _ value: Optional<Value>,
        animation: ShimmerAnimation = .default,
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

    /// Redacts content with a shimmering effect
    public func shimmer(
        isActive: Bool = true,
        duration: TimeInterval = 1.25,
        delay: TimeInterval = 0,
        isSynchronized: Bool = false
    ) -> some View {
        shimmer(
            isActive: isActive,
            animation: ShimmerAnimation(
                duration: duration,
                delay: delay,
                isSynchronized: isSynchronized
            )
        )
    }

    /// Redacts content with a shimmering effect
    public func shimmer(
        isActive: Bool = true,
        animation: ShimmerAnimation = .default
    ) -> some View {
        modifier(ShimmerModifier(isActive: isActive, animation: animation))
    }
}

@frozen
public struct ShimmerAnimation: Sendable {
    public var duration: TimeInterval
    public var delay: TimeInterval
    public var isSynchronized: Bool
    public var startPoint: UnitPoint
    public var endPoint: UnitPoint

    public init(
        duration: TimeInterval,
        delay: TimeInterval,
        isSynchronized: Bool = false,
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) {
        self.duration = duration
        self.delay = delay
        self.isSynchronized = isSynchronized
        self.startPoint = startPoint
        self.endPoint = endPoint
    }

    public static let `default` = ShimmerAnimation(duration: 1.25, delay: 0)
}

/// A modifier that redacts content and overlays a shimmering effect.
///
/// All active shimmer effects are synchronized to the same clock.
///
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
public struct ShimmerModifier: ViewModifier {
    var isActive: Bool
    var animation: ShimmerAnimation

    public init(isActive: Bool, animation: ShimmerAnimation = .default) {
        self.isActive = isActive
        self.animation = animation
    }

    public func body(content: Content) -> some View {
        content
            .disabled(isActive)
            .redacted(reason: isActive ? .placeholder : [])
            .mask(mask)
    }

    @ViewBuilder
    private var mask: some View {
        ZStack {
            Rectangle()
                .scale(1000)
                .ignoresSafeArea()
                .invertedMask {
                    if isActive {
                        Rectangle()
                    }
                }

            if isActive {
                GradientMask(animation: animation)
            }
        }
    }

    private struct GradientMask: View {
        var animation: ShimmerAnimation

        var body: some View {
            if animation.isSynchronized {
                SynchronizedGradientMask(animation: animation)
            } else {
                LocalizedGradientMask(animation: animation)
            }
        }
    }

    private struct SynchronizedGradientMask: View {
        var animation: ShimmerAnimation

        @ObservedObject var clock = ShimmerClock.shared

        var body: some View {
            let phase = clock.phase(
                duration: animation.duration,
                delay: animation.delay
            )
            LinearGradient(
                gradient:
                    Gradient(
                        stops: [
                            .init(color: Color.black, location: -1 + (2 * phase)),
                            .init(color: Color.black.opacity(0.3), location: (2 * phase) - 2 / 3),
                            .init(color: Color.black.opacity(0.3), location: (2 * phase) - 1 / 3),
                            .init(color: Color.black, location: 2 * phase)
                        ]
                    )
                ,
                startPoint: animation.startPoint,
                endPoint: animation.endPoint
            )
            .onAppear { clock.register() }
            .onDisappear { clock.unregister() }
        }
    }

    private struct LocalizedGradientMask: View {
        var animation: ShimmerAnimation

        @State var isAnimating = false

        var body: some View {
            LinearGradient(
                gradient:
                    Gradient(
                        colors: [
                            .black,
                            .black.opacity(0.3),
                            .black.opacity(0.3),
                            .black,
                        ]
                    )
                ,
                startPoint: .init(
                    x: animation.startPoint.x + (isAnimating ? 1 : -1),
                    y: animation.startPoint.y + (isAnimating ? 1 : -1)
                ),
                endPoint: .init(
                    x: animation.endPoint.x + (isAnimating ? 1 : -1),
                    y: animation.endPoint.y + (isAnimating ? 1 : -1)
                )
            )
            .animation(.linear(duration: animation.duration).delay(animation.delay).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear {
                withCATransaction {
                    isAnimating = true
                }
            }
        }
    }
}

private class ShimmerClock: ObservableObject {

    @Published private var elapsed: TimeInterval = 0

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
        let elapsed = displayLink.targetTimestamp - displayLink.timestamp
        onClockTick(step: elapsed)
    }
    #endif

    #if os(macOS)
    @objc
    private func onClockTick(timer: Timer) {
        onClockTick(step: timer.timeInterval)
    }
    #endif

    private func onClockTick(step: TimeInterval) {
        elapsed += step
    }

    func phase(duration: TimeInterval, delay: TimeInterval) -> CGFloat {
        let total = duration + delay
        let interval = elapsed.truncatingRemainder(dividingBy: total)
        let phase = max(0, min((interval - delay) / duration, 1))
        return phase
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
            elapsed = 0
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
                    HStack {
                        Color.blue
                            .frame(width: 150, height: 150)
                            .overlay(
                                Color.red
                                    .frame(width: 50, height: 50)
                                    .offset(x: 0, y: -75)
                            )
                            .shimmer(isActive: isActive)

                        Color.blue
                            .frame(width: 150, height: 150)
                            .overlay(
                                Color.red
                                    .frame(width: 50, height: 50)
                                    .offset(x: 0, y: -75)
                            )
                            .shimmer(isActive: isActive, isSynchronized: true)
                    }

                    HStack {
                        Color.blue
                            .frame(width: 100, height: 100)
                            .shimmer(
                                isActive: isActive,
                                duration: 0.3
                            )

                        Color.blue
                            .frame(width: 100, height: 100)
                            .shimmer(
                                isActive: isActive,
                                animation: .init(
                                    duration: 2,
                                    delay: 0.3,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Color.blue
                            .frame(width: 100, height: 100)
                            .shimmer(
                                isActive: isActive,
                                animation: .init(
                                    duration: 2,
                                    delay: 0.3,
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text(verbatim: isActive ? "Placeholder" : "Line 1, Line 2, Line 3")
                        .border(Color.red)

                    HStack {
                        Text(verbatim: isActive ? "Placeholder" : "Line 1, Line 2, Line 3")
                            .shimmer(isActive: isActive)

                        Text("Trailing")
                    }

                    HStack {
                        Text(verbatim: isActive ? "Placeholder" : "Line 1, Line 2, Line 3")
                            .shimmer(
                                isActive: isActive,
                                duration: 1.5,
                                delay: 0.25
                            )

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

                #if os(iOS)
                CollectionView(.compositional(axis: .horizontal, spacing: 8)) {
                    ForEach(0..<10, id: \.self) { _ in
                        Color.blue
                            .frame(width: 100, height: 100)
                            .shimmer(
                                isActive: isActive,
                                duration: 2,
                                delay: 0,
                                isSynchronized: true
                            )
                    }
                }
                .frame(height: 100)
                #endif

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
