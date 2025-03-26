//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Combine

/// A modifier that overlays a Metal layer filter that intensifies the vibrancy
@frozen
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct VibrancyEffectModifier: ViewModifier {

    @usableFromInline
    var intensity: Double?

    @inlinable
    public init(intensity: Double? = nil) {
        self.intensity = intensity
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                VibrancyEffectViewBody(intensity: intensity)
            )
    }
}

/// A Metal layer filter that intensifies the vibrancy
@frozen
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct VibrancyEffectView: View {

    @usableFromInline
    var intensity: Double?

    @inlinable
    public init(intensity: Double? = nil) {
        self.intensity = intensity
    }

    public var body: some View {
        VibrancyEffectViewBody(intensity: intensity)
    }
}

@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension View {

    /// A modifier that overlays a Metal layer that intensifies the vibrancy
    @inlinable
    public func vibrant() -> some View {
        modifier(VibrancyEffectModifier(intensity: nil))
    }

    /// A modifier that overlays a Metal layer that intensifies the vibrancy
    @inlinable
    public func vibrancy(intensity: Double? = nil) -> some View {
        modifier(VibrancyEffectModifier(intensity: intensity))
    }
}

@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct VibrancyEffectViewBody: View {

    var intensity: Double?

    #if os(iOS)
    @State var brightness = UIScreen.main.brightness

    var body: some View {
        HDRLayerViewRepresentable()
            .blendMode(.multiply)
            .allowsHitTesting(false)
            .opacity((intensity ?? 1) * brightness)
            .onReceive(
                NotificationCenter.default.publisher(for: UIScreen.brightnessDidChangeNotification)
            ) { _ in
                brightness = UIScreen.main.brightness
            }
    }
    #else
    var body: Never {
        bodyError()
    }
    #endif
}

#if os(iOS)
private struct HDRLayerViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> HDRLayerView {
        let uiView = HDRLayerView()
        return uiView
    }

    func updateUIView(_ uiView: HDRLayerView, context: Context) { }
}

private class HDRLayerView: UIView {

    var commandQueue: MTLCommandQueue?
    var library: MTLLibrary?

    var metalLayer: CAMetalLayer { layer as! CAMetalLayer }
    override class var layerClass: AnyClass { CAMetalLayer.self }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        let device = MTLCreateSystemDefaultDevice()
        commandQueue = device?.makeCommandQueue()
        library = device?.makeDefaultLibrary()
        metalLayer.device = device

        // Enable HDR content
        metalLayer.setValue(NSNumber(booleanLiteral: true), forKey: "wantsExtendedDynamicRangeContent")

        metalLayer.pixelFormat = .bgr10a2Unorm
        if #available(iOS 13.4, *) {
            metalLayer.colorspace = CGColorSpace(name: CGColorSpace.displayP3_PQ)
        } else {
            metalLayer.colorspace = CGColorSpace(name: CGColorSpace.displayP3_HLG)
        }
        metalLayer.framebufferOnly = false
        metalLayer.backgroundColor = nil
        metalLayer.isOpaque = false

        // Change the blending mode to screen or add to brighten underlying content
        metalLayer.compositingFilter = "multiplyBlendMode"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        render()
        CATransaction.commit()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsDisplay()
    }

    private func render() {
        #if targetEnvironment(simulator)
        let isHDRSupported = true
        #else
        let isHDRSupported = window?.screen.traitCollection.displayGamut == .P3
        #endif
        isHidden = !isHDRSupported
        guard isHDRSupported else { return }

        guard let drawable = metalLayer.nextDrawable() else { return }

        // Create a texture to sample the underlying content if needed
        // This part would require more complex Metal code to sample the view beneath
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = drawable.texture
        descriptor.colorAttachments[0].loadAction = .clear
        // Use a much brighter color for HDR - these values can go beyond 1.0 for HDR
        // Using PQ color space, values like 3.0 or higher will appear very bright on HDR displays
        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 0.5)
        descriptor.colorAttachments[0].storeAction = .store

        guard
            let buffer = commandQueue?.makeCommandBuffer(),
            let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }
}
#endif

// MARK: - Previews

#if os(iOS)
struct HDR_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var isExpanded = true

        struct ContentView: View {
            var body: some View {
                Color.blue
                    .overlay(
                        Text("Hello, World").foregroundColor(.white)
                    )
            }
        }

        var body: some View {
            VStack(spacing: 0) {
                Group {
                    ContentView()

                    ContentView()
                        .vibrancy(intensity: 0.25)

                    ContentView()
                        .vibrancy(intensity: 0.5)

                    ContentView()
                        .vibrancy(intensity: 0.75)

                    ContentView()
                        .vibrant()

                    ContentView()
                }
                .scaleEffect(isExpanded ? 1 : 0.5)
                .frame(height: isExpanded ? 100 : 80)
            }
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
        }
    }
}
#endif
