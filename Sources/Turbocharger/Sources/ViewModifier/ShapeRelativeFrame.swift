//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

public protocol LayoutShape: Shape {

    nonisolated func layoutSizeThatFits(_ size: CGSize) -> CGSize
}

/// A view modifier that transforms a views frame to the size of a shape
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct ShapeRelativeFrameModifier<S: LayoutShape>: ViewModifier {

    public var shape: S

    @inlinable
    public init(shape: S) {
        self.shape = shape
    }

    public func body(content: Content) -> some View {
        ShapeRelativeFrameLayout(shape: shape) {
            UnaryViewAdaptor {
                content
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension View {

    /// A view modifier that transforms a views frame to the size of a shape
    @inlinable
    public func shapeRelativeFrame<S: LayoutShape>(
        _ shape: S
    ) -> some View {
        modifier(ShapeRelativeFrameModifier(shape: shape))
    }
}

extension Circle: LayoutShape {

    public nonisolated func layoutSizeThatFits(_ size: CGSize) -> CGSize {
        let diameter = max(size.width, size.height)
        return CGSize(width: diameter, height: diameter)
    }
}

extension Capsule: LayoutShape {

    public nonisolated func layoutSizeThatFits(_ size: CGSize) -> CGSize {
        var size = size
        size.width += size.height
        return size
    }
}

extension Rectangle: LayoutShape {

    public nonisolated func layoutSizeThatFits(_ size: CGSize) -> CGSize {
        return size
    }
}

extension RoundedRectangle: LayoutShape {

    public nonisolated func layoutSizeThatFits(_ size: CGSize) -> CGSize {
        var size = size
        size.width += 2 * cornerSize.width
        return size
    }
}

@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct ShapeRelativeFrameLayout<S: LayoutShape>: Layout {

    public var shape: S

    @inlinable
    public init(shape: S) {
        self.shape = shape
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        var size = sizeThatFits(proposal: .infinity, subviews: subviews)
        size = shape.layoutSizeThatFits(size)
        let idealSize = size
        if let proposedWidth = proposal.width {
            size.width = min(size.width, proposedWidth)
        }
        if let proposedHeight = proposal.height {
            size.height = min(size.height, proposedHeight)
        }
        let dx = idealSize.width - size.width
        let dy = idealSize.height - size.height
        if dx > 0 || dy > 0 {
            let insetSize = sizeThatFits(
                proposal: ProposedViewSize(
                    width: size.width - dx,
                    height: size.height - dy
                ),
                subviews: subviews
            )
            size.width = max(size.width, insetSize.width)
            size.height = max(size.height, insetSize.height)
        }
        return size
    }

    private func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> CGSize {
        var size = CGSize.zero
        for subview in subviews {
            let sizeThatFits = subview.sizeThatFits(proposal)
            size.width = max(size.width, sizeThatFits.width)
            size.height = max(size.height, sizeThatFits.height)
        }
        return size
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        for subview in subviews {
            var size = bounds.size
            var idealSize = subview.sizeThatFits(ProposedViewSize(size))
            idealSize = shape.layoutSizeThatFits(size)
            let dx = idealSize.width - size.width
            let dy = idealSize.height - size.height
            if dx > 0 || dy > 0 {
                size = sizeThatFits(
                    proposal: ProposedViewSize(
                        width: size.width - dx,
                        height: size.height - dy
                    ),
                    subviews: subviews
                )
            }
            subview.place(
                at: CGPoint(x: bounds.midX, y: bounds.midY),
                anchor: .center,
                proposal: ProposedViewSize(size)
            )
        }
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct ShapeRelativeFrameModifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let views = Group {
                Text("Hello, World")
                    .border(Color.blue)
                    .shapeRelativeFrame(.capsule)
                    .background(Capsule().fill(Color.blue.opacity(0.3)))

                Text("Hello, World")
                    .border(Color.blue)
                    .shapeRelativeFrame(.circle)
                    .background(Circle().fill(Color.blue.opacity(0.3)))

                Text("Hello, World")
                    .border(Color.blue)
                    .shapeRelativeFrame(RoundedRectangle(cornerRadius: 8))
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.3)))

                Text("Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat.")
                    .frame(maxWidth: 300)
                    .border(Color.blue)
                    .shapeRelativeFrame(RoundedRectangle(cornerRadius: 32))
                    .background(Capsule().fill(Color.blue.opacity(0.3)))
            }

            ScrollView {
                VStack {
                    views

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            views
                        }
                    }
                }
            }
        }
    }
}
