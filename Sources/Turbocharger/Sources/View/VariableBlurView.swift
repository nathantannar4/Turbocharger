//
// Copyright (c) Nathan Tannar
//

import SwiftUI
#if canImport(CoreImage)
import CoreImage.CIFilterBuiltins
#endif
import Engine

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct VariableBlurView: View {

    public var radius: CGFloat
    public var startPoint: UnitPoint
    public var endPoint: UnitPoint

    public init(
        radius: CGFloat = 20,
        startPoint: UnitPoint,
        endPoint: UnitPoint
    ) {
        self.radius = radius
        self.startPoint = startPoint
        self.endPoint = endPoint
    }

    public var body: some View {
        #if os(watchOS) || os(tvOS)
        EmptyView()
        #else
        VariableBlurViewBody(
            radius: radius,
            startPoint: startPoint,
            endPoint: endPoint
        )
        #endif
    }
}

#if !os(watchOS) && !os(tvOS)

@available(watchOS, unavailable)
private struct VariableBlurViewBody: PlatformViewRepresentable {

    var radius: CGFloat
    var startPoint: UnitPoint
    var endPoint: UnitPoint

    func makeView(context: Context) -> VariableBlurLayerView {
        let uiView = VariableBlurLayerView(
            radius: radius,
            startPoint: startPoint,
            endPoint: endPoint
        )
        return uiView
    }

    func updateView(_ uiView: VariableBlurLayerView, context: Context) {
        uiView.radius = radius
        uiView.startPoint = startPoint
        uiView.endPoint = endPoint
    }
}

@available(watchOS, unavailable)
open class VariableBlurLayerView: PlatformView {

    public var radius: CGFloat {
        didSet {
            guard radius != oldValue else { return }
            needsFilterUpdate = true
        }
    }

    public var startPoint: UnitPoint {
        didSet {
            guard startPoint != oldValue else { return }
            needsFilterUpdate = true
        }
    }

    public var endPoint: UnitPoint {
        didSet {
            guard endPoint != oldValue else { return }
            needsFilterUpdate = true
        }
    }

    #if os(macOS)
    open override var wantsUpdateLayer: Bool {
        return true
    }
    #else
    public override class var layerClass: AnyClass {
        return makeLayerClass()
    }
    #endif

    private var needsFilterUpdate = true {
        didSet {
            if needsFilterUpdate {
                #if os(macOS)
                updateLayer()
                #else
                setNeedsDisplay()
                #endif
            }
        }
    }

    init(
        radius: CGFloat,
        startPoint: UnitPoint,
        endPoint: UnitPoint
    ) {
        self.radius = radius
        self.startPoint = startPoint
        self.endPoint = endPoint
        super.init(frame: .zero)
        #if os(macOS)
        wantsLayer = true
        updateFilter()
        #else
        isUserInteractionEnabled = false
        #endif
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if os(macOS)
    open override func makeBackingLayer() -> CALayer {
        let layerClass = Self.makeLayerClass() as! CALayer.Type
        return layerClass.init()
    }
    #endif

    private class func makeLayerClass() -> AnyClass {
        guard
            let className = String(data: Data(base64Encoded: "Q0FCYWNrZHJvcExheWVy")!, encoding: .utf8), // CABackdropLayer
            let CABackdropLayer = NSClassFromString(className) as? CALayer.Type
        else {
            return CALayer.self
        }
        return CABackdropLayer
    }

    private func makeCAFilter() -> NSObject? {
        guard
            let className = String(data: Data(base64Encoded: "Q0FGaWx0ZXI=")!, encoding: .utf8), // CAFilter
            let CAFilter = NSClassFromString(className) as? NSObject.Type,
            let filter = CAFilter.perform(NSSelectorFromString("filterWithType:"), with: "variableBlur").takeUnretainedValue() as? NSObject
        else {
            return nil
        }
        return filter
    }

    #if os(macOS)
    open override func updateLayer() {
        super.updateLayer()
        updateFilter()
    }
    #else
    open override func draw(_ rect: CGRect) {
        if needsFilterUpdate {
            updateFilter()
        }
        super.draw(rect)
    }
    #endif

    private func updateFilter() {
        needsFilterUpdate = false
        guard let filter = makeCAFilter() else { return }
        let size: CGFloat = 10

        let gradientFilter = CIFilter.linearGradient()
        gradientFilter.color0 = CIColor.black
        gradientFilter.color1 = CIColor.clear
        gradientFilter.point0 = CGPoint(
            x: startPoint.x * size,
            y: endPoint.y * size
        )
        gradientFilter.point1 = CGPoint(
            x: endPoint.x * size,
            y: startPoint.y * size
        )
        let mask = CIContext().createCGImage(
            gradientFilter.outputImage!,
            from: CGRect(
                origin: CGPoint(
                    x: 0,
                    y: (endPoint.y + startPoint.y - 1) * size
                ),
                size: CGSize(
                    width: size,
                    height: size
                )
            )
        )!

        filter.setValue(radius, forKey: "inputRadius")
        filter.setValue(mask, forKey: "inputMaskImage")
        filter.setValue(true, forKey: "inputNormalizeEdges")

        #if os(macOS)
        layer?.filters = [filter]
        #else
        layer.filters = [filter]
        #endif
    }

    #if os(macOS)
    open override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
    #else
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
    #endif
}

// MARK: - Previews

@available(watchOS, unavailable)
struct VariableBlurView_Previews: PreviewProvider {
    struct Preview: View {
        @State var radius: CGFloat = 40
        var body: some View {
            VStack {
                VStack(spacing: 0) {
                    Text("Title")
                        .frame(maxWidth: .infinity, minHeight: 44)

                    Text("Subtitle")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .background(
                    GeometryReader { proxy in
                        let startPoint = UnitPoint(
                            x: 0.5,
                            y: (proxy.size.height / (proxy.size.height + proxy.safeAreaInsets.top - 22))
                        )
                        let endPoint = UnitPoint(
                            x: 0.5,
                            y: 1
                        )
                        HStack(spacing: 0) {
                            LinearGradient(
                                colors: [
                                    .black,
                                    .clear
                                ],
                                startPoint: startPoint,
                                endPoint: endPoint
                            )
                            .edgesIgnoringSafeArea(.all)

                            VariableBlurView(
                                radius: 2,
                                startPoint: startPoint,
                                endPoint: endPoint
                            )
                            .edgesIgnoringSafeArea(.all)
                        }
                        .onAppear {
                            print(startPoint, endPoint)
                        }
                    }
                )
                .background(
                    Text(String(repeating: "*", count: 1000))
                        .truncationMode(.middle)
                        .frame(height: 140)
                        .edgesIgnoringSafeArea(.all)
                )

                Spacer()

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .yellow, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .overlay(
                        VariableBlurView(
                            radius: radius,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text(radius.rounded().description)

                Slider(value: $radius, in: 0...50)
                    .padding(.horizontal)

                let content = Text("Hello World\nHello World\nHello World")
                let radius = radius / 10

                HStack {
                    content
                        .overlay(
                            LinearGradient(
                                colors: [
                                    .black,
                                    .clear
                                ],
                                startPoint: .init(x: 0.5, y: -2),
                                endPoint: .bottom
                            )
                        )

                    content
                        .overlay(
                            VariableBlurView(
                                radius: radius,
                                startPoint: .init(x: 0.5, y: -2),
                                endPoint: .bottom
                            )
                        )

                    content
                        .overlay(
                            VariableBlurView(
                                radius: radius,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    content
                        .overlay(
                            LinearGradient(
                                colors: [
                                    .black,
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                HStack {
                    content
                        .overlay(
                            LinearGradient(
                                colors: [
                                    .black,
                                    .clear
                                ],
                                startPoint: .init(x: 0.5, y: 2),
                                endPoint: .top
                            )
                        )

                    content
                        .overlay(
                            VariableBlurView(
                                radius: radius,
                                startPoint: .init(x: 0.5, y: 2),
                                endPoint: .top
                            )
                        )

                    content
                        .overlay(
                            VariableBlurView(
                                radius: radius,
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )

                    content
                        .overlay(
                            LinearGradient(
                                colors: [
                                    .black,
                                    .clear
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                }

                HStack {
                    content
                        .overlay(
                            LinearGradient(
                                colors: [
                                    .black,
                                    .clear
                                ],
                                startPoint: .init(x: -1, y: 0.5),
                                endPoint: .trailing
                            )
                        )

                    content
                        .overlay(
                            VariableBlurView(
                                radius: radius,
                                startPoint: .init(x: -1, y: 0.5),
                                endPoint: .trailing
                            )
                        )

                    content
                        .overlay(
                            VariableBlurView(
                                radius: radius,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    content
                        .overlay(
                            LinearGradient(
                                colors: [
                                    .black,
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                HStack {
                    content
                        .overlay(
                            LinearGradient(
                                colors: [
                                    .black,
                                    .clear
                                ],
                                startPoint: .init(x: 2, y: 0.5),
                                endPoint: .leading
                            )
                        )

                    content
                        .overlay(
                            VariableBlurView(
                                radius: radius,
                                startPoint: .init(x: 2, y: 0.5),
                                endPoint: .leading
                            )
                        )

                    content
                        .overlay(
                            VariableBlurView(
                                radius: radius,
                                startPoint: .trailing,
                                endPoint: .leading
                            )
                        )

                    content
                        .overlay(
                            LinearGradient(
                                colors: [
                                    .black,
                                    .clear
                                ],
                                startPoint: .trailing,
                                endPoint: .leading
                            )
                        )
                }
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}

#endif
