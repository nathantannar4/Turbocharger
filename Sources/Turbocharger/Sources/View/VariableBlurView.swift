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
        let size = CGSize(width: 50, height: 50)

        let gradientFilter = CIFilter.smoothLinearGradient()
        gradientFilter.color0 = CIColor.black
        gradientFilter.color1 = CIColor.clear
        gradientFilter.point0 = CGPoint(
            x: startPoint.x * size.width,
            y: startPoint.y * size.height
        )
        gradientFilter.point1 = CGPoint(
            x: endPoint.x * size.width,
            y: endPoint.y * size.height
        )
        let mask = CIContext().createCGImage(
            gradientFilter.outputImage!,
            from: CGRect(origin: .zero, size: size)
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
    #endif
}

// MARK: - Previews

@available(watchOS, unavailable)
struct VariableBlurView_Previews: PreviewProvider {
    struct Preview: View {
        @State var radius: CGFloat = 20
        var body: some View {
            VStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .red, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 300, height: 300)
                    .overlay(
                        VariableBlurView(
                            radius: radius,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text(radius.rounded().description)

                Slider(value: $radius, in: 0...50)

                HStack {
                    Text("Hello\nWorld")
                        .overlay(
                            VariableBlurView(
                                radius: 1,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Hello\nWorld")
                        .overlay(
                            VariableBlurView(
                                radius: 1,
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                }

                HStack {
                    Text("Hello\nWorld")
                        .overlay(
                            VariableBlurView(
                                radius: 1,
                                startPoint: .top,
                                endPoint: .init(x: 0.5, y: 2)
                            )
                        )

                    Text("Hello\nWorld")
                        .overlay(
                            VariableBlurView(
                                radius: 1,
                                startPoint: .bottom,
                                endPoint: .init(x: 0.5, y: -1)
                            )
                        )
                }

                HStack {
                    Text("Hello World")
                        .overlay(
                            VariableBlurView(
                                radius: 1,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Hello World")
                        .overlay(
                            VariableBlurView(
                                radius: 1,
                                startPoint: .trailing,
                                endPoint: .leading
                            )
                        )
                }

                Text("Hello World")
                    .overlay(
                        VariableBlurView(
                            radius: 1,
                            startPoint: .leading,
                            endPoint: .init(x: 2, y: 0.5)
                        )
                    )
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}

#endif
