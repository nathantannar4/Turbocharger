//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Combine
import Engine

#if !os(watchOS)

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
@frozen
public struct FluidGradient: View {

    @usableFromInline
    var colors: [Color]

    @usableFromInline
    var backgroundColors: [Color]

    @usableFromInline
    var blurRadius: CGFloat

    @inlinable
    public init(colors: [Color], blurRadius: CGFloat = 50) {
        self.init(colors: colors, backgroundColors: colors, blurRadius: blurRadius)
    }

    @inlinable
    public init(colors: [Color], backgroundColors: [Color], blurRadius: CGFloat = 50) {
        self.colors = colors
        self.backgroundColors = backgroundColors
        self.blurRadius = blurRadius
    }

    public var body: some View {
        FluidGradientBody(
            colors: colors,
            backgroundColors: backgroundColors
        )
        .blur(radius: blurRadius, opaque: !backgroundColors.isEmpty)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
private struct FluidGradientBody: View {

    var colors: [Color]
    var backgroundColors: [Color]

    @State private var isVisible = false

    var body: some View {
        FluidGradientLayerAdapter(
            colors: colors,
            backgroundColors: backgroundColors,
            isAnimating: isVisible
        )
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
private struct FluidGradientLayerAdapter: CALayerRepresentable {

    var colors: [Color]
    var backgroundColors: [Color]
    var isAnimating: Bool

    func makeCALayer(
        _ layer: FluidGradientLayer,
        context: Context
    ) {
        context.coordinator.layer = layer
    }

    func updateCALayer(
        _ layer: FluidGradientLayer,
        context: Context
    ) {
        layer.onUpdate(
            colors: colors,
            backgroundColors: backgroundColors,
            context: context
        )
        context.coordinator.isAnimating = isAnimating
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {

        weak var layer: FluidGradientLayer?
        var timer: AnyCancellable?
        var lastTick: Date?

        var isAnimating = false {
            didSet {
                guard isAnimating != oldValue else { return }
                if isAnimating {
                    start()
                } else {
                    timer = nil
                }
            }
        }

        private func start() {
            let duration: TimeInterval = 15
            // Resume the existing cycle if the previous animations are still in flight
            let elapsed = lastTick.map { Date().timeIntervalSince($0) } ?? duration
            let delay = max(0, duration - elapsed)
            timer = Just(Date())
                .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
                .flatMap { _ in
                    Timer.publish(every: duration, on: .main, in: .default)
                        .autoconnect()
                        .prepend(Date())
                }
                .receive(on: DispatchQueue.main)
                .sink { [unowned self] date in
                    self.lastTick = date
                    withCATransaction {
                        CATransaction.setDisableActions(true)
                        self.layer?.onClockTick(duration: duration)
                    }
                }
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
private class FluidGradientLayer: CALayer {

    private var colors: [CGColor] = []
    private var backgroundColors: [CGColor] = []
    private var backgroundGradientLayer = CAGradientLayer()
    private var backgroundFluidLayers: [FluidLayer] = []
    private let backgroundLayer = CALayer()
    private var foregroundFluidLayers: [FluidLayer] = []
    private let foregroundLayer = CALayer()
    private var isPendingLayout = false

    override init() {
        super.init()

        #if os(macOS)
        autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        backgroundLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        foregroundLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        #endif

        backgroundGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        backgroundGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        foregroundLayer.compositingFilter = CIFilter(name: "CIOverlayBlendMode")

        addSublayer(backgroundLayer)
        backgroundLayer.addSublayer(backgroundGradientLayer)
        addSublayer(foregroundLayer)
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        func layout(layer: CALayer) {
            for sublayer in layer.sublayers ?? [] {
                sublayer.frame = layer.bounds
                layout(layer: sublayer)
            }
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layout(layer: self)
        CATransaction.commit()

        if isPendingLayout {
            update()
        }
    }

    func onUpdate(
        colors: [Color],
        backgroundColors: [Color],
        context: FluidGradientLayerAdapter.Context
    ) {
        let colors = colors.map { $0.toCGColor(in: context.environment) }
        let backgroundColors = backgroundColors.map { $0.toCGColor(in: context.environment) }
        guard colors != self.colors || backgroundColors != self.backgroundColors else { return }
        self.colors = colors
        self.backgroundColors = backgroundColors
        CATransaction.begin()
        update()
        CATransaction.commit()
    }

    func onClockTick(duration: TimeInterval) {
        backgroundGradientLayer.removeAllAnimations()
        update()

        let backgroundColors = backgroundColors.shuffled()
        if duration > 0 {
            let layer = backgroundGradientLayer.presentation() ?? backgroundGradientLayer
            let colorsAnimation = CABasicAnimation.gradientAnimation(
                keyPath: "colors",
                from: layer.colors,
                to: backgroundColors,
                duration: duration
            )
            backgroundGradientLayer.add(
                colorsAnimation,
                forKey: "colors"
            )
        } else {
            backgroundGradientLayer.colors = backgroundColors
        }

        for layer in backgroundFluidLayers {
            layer.move(
                to: .random(),
                radius: CGFloat.random(in: 0.25...0.75),
                duration: duration
            )
        }
        for layer in foregroundFluidLayers {
            layer.move(
                to: .random(),
                radius: CGFloat.random(in: 0.15...0.5),
                duration: duration
            )
        }
    }

    private func update() {
        backgroundGradientLayer.colors = backgroundColors

        guard bounds.size != .zero else {
            isPendingLayout = true
            return
        }
        isPendingLayout = false

        update(
            layers: &backgroundFluidLayers,
            in: backgroundLayer,
            colors: colors
        )
        update(
            layers: &foregroundFluidLayers,
            in: foregroundLayer,
            colors: [colors, colors].flatMap { $0 }
        )
    }

    private func update(
        layers: inout [FluidLayer],
        in layer: CALayer,
        colors: [CGColor]
    ) {
        layers.reserveCapacity(colors.count)
        while layers.count > colors.count {
            layers.removeLast().removeFromSuperlayer()
        }
        for (index, color) in colors.enumerated() {
            if layers.count > index {
                let sublayer = layers[index]
                sublayer.color = color
            } else {
                let sublayer = FluidLayer()
                sublayer.color = color
                sublayer.frame = layer.bounds
                let startPoint = CGPoint(unitPoint: .random())
                sublayer.startPoint = startPoint
                sublayer.endPoint = startPoint
                layers.append(sublayer)
                layer.addSublayer(sublayer)
            }
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
final class FluidLayer: CAGradientLayer {

    var color: CGColor? {
        didSet {
            if oldValue != color {
                if let color {
                    colors = [
                        color,
                        color,
                        color.copy(alpha: 0) ?? CGColor(gray: 0, alpha: 0)
                    ]
                    locations = [0.0, 0.9, 0.99]
                } else {
                    colors = nil
                    locations = nil
                }
            }
        }
    }

    override init() {
        super.init()

        type = .radial
        #if os(macOS)
        autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        #endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    func move(
        to location: UnitPoint,
        radius: CGFloat,
        duration: CGFloat
    ) {
        let startPoint = CGPoint(unitPoint: location)
        let endPoint = startPoint.displace(by: radius, in: bounds.size)

        if duration <= 0 {
            self.startPoint = startPoint
            self.endPoint = endPoint
            return
        }

        let layer = presentation() ?? self
        let startPointAnimation = CASpringAnimation.fluidAnimation(
            keyPath: "startPoint",
            from: layer.startPoint,
            to: startPoint,
            duration: duration
        )
        let endPointAnimation = CASpringAnimation.fluidAnimation(
            keyPath: "endPoint",
            from: layer.endPoint,
            to: endPoint,
            duration: duration
        )
        let opacityAnimation = CASpringAnimation.fluidAnimation(
            keyPath: "opacity",
            from: layer.opacity,
            to: Float.random(in: 0.2...1),
            duration: duration
        )
        add(opacityAnimation, forKey: "opacity")
        add(startPointAnimation, forKey: "startPoint")
        add(endPointAnimation, forKey: "endPoint")
    }
}

extension CABasicAnimation {
    static func gradientAnimation(
        keyPath: String,
        from fromValue: Any?,
        to toValue: Any?,
        duration: TimeInterval
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = duration
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        return animation
    }
}

extension CASpringAnimation {
    static func fluidAnimation(
        keyPath: String,
        from fromValue: Any?,
        to toValue: Any?,
        duration: TimeInterval
    ) -> CASpringAnimation {
        let animation = CASpringAnimation(keyPath: keyPath)
        animation.initialVelocity = 0
        animation.mass = 50 * duration
        animation.damping = 10 * duration
        animation.duration = duration
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.fromValue = fromValue
        animation.toValue = toValue
        return animation
    }
}

extension UnitPoint {
    static func random() -> UnitPoint {
        UnitPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1))
    }
}

extension CGPoint {
    init(unitPoint: UnitPoint) {
        self.init(x: unitPoint.x, y: unitPoint.y)
    }

    func displace(by radius: CGFloat, in size: CGSize) -> CGPoint {
        let aspectRatio = size.width / max(size.height, 1)
        var point = self
        point.x += radius
        point.y += aspectRatio * radius
        return point
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
struct FluidGradient_Previews: PreviewProvider {
    static var previews: some View {
        Preview(colors: [
            .red, .yellow, .orange, .primary
        ])

        Preview(colors: [
            .green, .yellow, .blue, .primary
        ])
    }

    struct Preview: View {
        var colors: [Color]

        @State var isHidden = false
        @State var isDark = false

        var body: some View {
            ZStack {
                if !isHidden {
                    FluidGradient(colors: colors)
                        .ignoresSafeArea()
                        .environment(\.colorScheme, isDark ? .dark : nil)
                }

                VStack {
                    Button {
                        isHidden.toggle()
                    } label: {
                        Text("isHidden")
                    }

                    Button {
                        isDark.toggle()
                    } label: {
                        Text("isDark")
                    }
                }
            }
        }
    }
}

#endif
