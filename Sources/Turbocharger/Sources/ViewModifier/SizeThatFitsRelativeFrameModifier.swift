//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A view modifier that transforms a views frame based on its size that fits
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct SizeThatFitsRelativeFrameModifier: ViewModifier {

    public var transform: (CGSize) -> CGSize

    @inlinable
    public init(
        transform: @escaping (CGSize) -> CGSize
    ) {
        self.transform = transform
    }

    public func body(content: Content) -> some View {
        SizeThatFitsRelativeFrameLayout(transform: transform) {
            content
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension View {

    /// A view modifier that transforms a views frame based on its size that fits
    @inlinable
    public func sizeThatFitsRelativeFrame(
        transform: @escaping (CGSize) -> CGSize
    ) -> some View {
        modifier(SizeThatFitsRelativeFrameModifier(transform: transform))
    }
}

@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct SizeThatFitsRelativeFrameLayout: Layout {

    public var transform: (CGSize) -> CGSize

    @inlinable
    public init(transform: @escaping (CGSize) -> CGSize) {
        self.transform = transform
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
        return transform(size)
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

/// A view modifier that transforms a views frame to the size of a shape
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct ShapeRelativeFrameModifier: ViewModifier {

    @frozen
    public enum Shape {
        case circle
        case capsule
    }
    public var shape: Shape

    @inlinable
    public init(shape: Shape) {
        self.shape = shape
    }

    public func body(content: Content) -> some View {
        content
            .sizeThatFitsRelativeFrame { size in
                switch shape {
                case .circle:
                    let size = max(size.width, size.height)
                    return CGSize(width: size, height: size)
                case .capsule:
                    return CGSize(
                        width: size.width + size.height,
                        height: size.height
                    )
                }
            }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension View {

    /// A view modifier that transforms a views frame to the size of a shape
    @inlinable
    public func shapeRelativeFrame(_ shape: ShapeRelativeFrameModifier.Shape) -> some View {
        modifier(ShapeRelativeFrameModifier(shape: shape))
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct SizeThatFitsRelativeFrameModifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello, World")
                .sizeThatFitsRelativeFrame { size in
                    CGSize(
                        width: size.width + size.height,
                        height: size.height
                    )
                }
                .background(Capsule().fill(Color.blue))

            Text("Hello, World")
                .padding(.vertical, 8)
                .shapeRelativeFrame(.capsule)
                .background(Capsule().fill(Color.blue))

            Text("Hello, World")
                .padding(.horizontal, 8)
                .shapeRelativeFrame(.circle)
                .background(Circle().fill(Color.blue))
        }
    }
}
