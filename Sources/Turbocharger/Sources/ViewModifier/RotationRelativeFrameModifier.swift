//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A view modifier that arranges its subviews that transforms a subviews size to account for a rotation angle.
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct RotationRelativeFrameModifier: ViewModifier {

    public var rotation: Angle

    @inlinable
    public init(rotation: Angle) {
        self.rotation = rotation
    }

    public func body(content: Content) -> some View {
        RotationRelativeFrameLayout(rotation: rotation) {
            content
                .rotationEffect(rotation, anchor: .center)
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension View {

    /// A view modifier that arranges its subviews that transforms a subviews size to account for a rotation angle.
    @inlinable
    public func rotationRelativeFrame(rotation: Angle) -> some View {
        modifier(RotationRelativeFrameModifier(rotation: rotation))
    }
}

/// A layout that transforms a subviews size to account for a rotation angle.
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct RotationRelativeFrameLayout: Layout {

    public var rotation: Angle

    @inlinable
    public init(rotation: Angle) {
        self.rotation = rotation
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        var size = CGSize.zero
        for subview in subviews {
            let sizeThatFits = subview.sizeThatFits(proposal)
            size.width = max(size.width, sizeThatFits.width)
            size.height = max(size.height, sizeThatFits.height)
        }
        let rect = CGRect(origin: .zero, size: size)
        let transform = CGAffineTransform(rotationAngle: rotation.radians)
        return rect.applying(transform).size
    }
    
    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        for subview in subviews {
            subview.place(
                at: CGPoint(x: bounds.midX, y: bounds.midY),
                anchor: .center,
                proposal: proposal
            )
        }
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct RotationRelativeFrameLayout_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            VStack {
                Image(systemName: "globe")

                Text("Hello, world!")
            }
            .border(Color.black)
            .padding()

            ZStack {
                Image(systemName: "globe")

                Text("Hello, world!")
            }
            .rotationRelativeFrame(rotation: .degrees(20))
            .border(Color.black)
            .padding()

            VStack {
                Image(systemName: "globe")

                Text("Hello, world!")
            }
            .rotationRelativeFrame(rotation: .degrees(90))
            .border(Color.black)
            .padding()
        }
    }
}
