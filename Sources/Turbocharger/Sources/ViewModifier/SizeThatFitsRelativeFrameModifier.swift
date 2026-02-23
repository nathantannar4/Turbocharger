//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A view modifier that transforms a views frame based on its size that fits
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct SizeThatFitsRelativeFrameModifier: ViewModifier {

    public var transform: @Sendable (CGSize) -> CGSize

    @inlinable
    public init(
        transform: @Sendable @escaping (CGSize) -> CGSize
    ) {
        self.transform = transform
    }

    public func body(content: Content) -> some View {
        SizeThatFitsRelativeFrameLayout(transform: transform) {
            UnaryViewAdaptor {
                content
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension View {

    /// A view modifier that transforms a views frame based on its size that fits
    @inlinable
    public func sizeThatFitsRelativeFrame(
        transform: @Sendable @escaping (CGSize) -> CGSize
    ) -> some View {
        modifier(SizeThatFitsRelativeFrameModifier(transform: transform))
    }
}

@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct SizeThatFitsRelativeFrameLayout: Layout {

    public var transform: @Sendable (CGSize) -> CGSize

    @inlinable
    public init(transform: @Sendable @escaping (CGSize) -> CGSize) {
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
        size = transform(size)
        if let proposedWidth = proposal.width {
            size.width = min(size.width, proposedWidth)
        }
        if let proposedHeight = proposal.height {
            size.height = min(size.height, proposedHeight)
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
            subview.place(
                at: CGPoint(x: bounds.midX, y: bounds.midY),
                anchor: .center,
                proposal: ProposedViewSize(bounds.size)
            )
        }
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct SizeThatFitsRelativeFrameModifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let views = Group {
                Text("Hello, World")
                    .sizeThatFitsRelativeFrame { size in
                        CGSize(
                            width: size.width,
                            height: size.height
                        )
                    }
                    .background(Color.blue)

                Group {
                    Text("Hello, World")

                    Text("Hello, World")
                }
                .sizeThatFitsRelativeFrame { size in
                    CGSize(
                        width: size.width,
                        height: size.height
                    )
                }
                .background(Color.blue)

                Text("Hello, World")
                    .sizeThatFitsRelativeFrame { size in
                        CGSize(
                            width: 2 * size.width,
                            height: 2 * size.height
                        )
                    }
                    .background(Color.blue)

                Text("Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat.")
                    .sizeThatFitsRelativeFrame { size in
                        CGSize(
                            width: 2 * size.width,
                            height: size.height
                        )
                    }
                    .background(Color.blue)
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
