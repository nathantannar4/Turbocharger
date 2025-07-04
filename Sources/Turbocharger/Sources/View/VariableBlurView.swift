//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import TurbochargerC

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
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
        _CALayerView(type: CABackdropLayer.self) { layer in
            guard let filter = CAFilter(type: "variableBlur") else { return }
            let size = CGSize(width: 50, height: 50)

            let startPoint = UnitPoint.top
            let endPoint = UnitPoint.bottom
            let gradientFilter = CIFilter.smoothLinearGradient()
            gradientFilter.color0 = CIColor.black
            gradientFilter.color1 = CIColor.clear
            gradientFilter.point0 = CGPoint(
                x: startPoint.x * size.width,
                y: endPoint.y * size.height
            )
            gradientFilter.point1 = CGPoint(
                x: endPoint.x * size.width,
                y: startPoint.y * size.height
            )
            let mask = CIContext().createCGImage(
                gradientFilter.outputImage!,
                from: CGRect(origin: .zero, size: size)
            )!

            filter.setValue(radius, forKey: "inputRadius")
            filter.setValue(mask, forKey: "inputMaskImage")
            filter.setValue(true, forKey: "inputNormalizeEdges")

            layer.filters = [filter]
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
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
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
