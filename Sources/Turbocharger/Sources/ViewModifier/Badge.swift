//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A modifier that adds a view as a badge
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct BadgeModifier<Label: View>: ViewModifier {

    public var alignment: Alignment
    public var anchor: UnitPoint
    public var scale: CGPoint
    public var inset: CGFloat
    public var label: Label

    public init(
        alignment: Alignment,
        anchor: UnitPoint = UnitPoint(x: 0.25, y: 0.25),
        scale: CGPoint,
        inset: CGFloat = 0,
        @ViewBuilder label: () -> Label
    ) {
        self.alignment = alignment
        self.anchor = anchor
        self.label = label()
        self.scale = scale
        self.inset = inset
    }

    public init(
        alignment: Alignment,
        anchor: UnitPoint = UnitPoint(x: 0.25, y: 0.25),
        scale: CGFloat,
        inset: CGFloat = 0,
        @ViewBuilder label: () -> Label
    ) {
        self.init(
            alignment: alignment,
            anchor: anchor,
            scale: CGPoint(x: scale, y: scale),
            inset: inset,
            label: label
        )
    }

    var badge: some View {
        label.alignmentGuideAdjustment(anchor: anchor)
    }

    public func body(content: Content) -> some View {
        content
            .invertedMask(alignment: alignment) {
                badge.modifier(
                    BadgeMaskEffect(scale: scale, inset: inset)
                )
            }
            .overlay(badge, alignment: alignment)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension View {

    /// A modifier that adds a view as a badge
    @inlinable
    public func badge<Label: View>(
        alignment: Alignment = .topTrailing,
        anchor: UnitPoint = UnitPoint(x: 0.25, y: 0.25),
        scale: CGPoint,
        inset: CGFloat = 0,
        @ViewBuilder label: () -> Label
    ) -> some View {
        modifier(
            BadgeModifier(
                alignment: alignment,
                anchor: anchor,
                scale: scale,
                inset: inset,
                label: label
            )
        )
    }

    /// A modifier that adds a view as a badge
    @inlinable
    public func badge<Label: View>(
        alignment: Alignment = .topTrailing,
        anchor: UnitPoint = UnitPoint(x: 0.25, y: 0.25),
        scale: CGFloat = 1,
        inset: CGFloat = 0,
        @ViewBuilder label: () -> Label
    ) -> some View {
        badge(
            alignment: alignment,
            anchor: anchor,
            scale: CGPoint(x: scale, y: scale),
            inset: inset,
            label: label
        )
    }
}

private struct BadgeMaskEffect: GeometryEffect {
    var scale: CGPoint
    var inset: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let dx = scale.x * (size.width + inset) / size.width
        let dy = scale.y * (size.height + inset) / size.height
        let x = size.width * (dx - 1) / 2
        let y = size.height * (dy - 1) / 2
        return ProjectionTransform(
            CGAffineTransform(translationX: -x, y: -y)
                .scaledBy(x: dx, y: dy)
        )
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct BadgeModifier_Previews: PreviewProvider {
    struct Badge: View {
        var body: some View {
            Capsule()
                .fill(Color.blue)
                .frame(width: 40, height: 20)
        }
    }

    static var previews: some View {
        VStack(spacing: 44) {
            Rectangle()
                .badge(alignment: .topLeading) {
                    Badge()
                }
                .badge(alignment: .topTrailing) {
                    Badge()
                }
                .badge(alignment: .bottomLeading) {
                    Badge()
                }
                .badge(alignment: .bottomTrailing) {
                    Badge()
                }
                .shadow(color: .black, radius: 50, x: 0, y: 0)
                .frame(width: 100, height: 100)

            HStack {
                Circle()
                    .badge(alignment: .topLeading) {
                        Badge()
                    }

                Circle()
                    .badge(alignment: .topTrailing) {
                        Badge()
                    }

                Circle()
                    .badge(alignment: .bottomLeading) {
                        Badge()
                    }

                Circle()
                    .badge(alignment: .bottomTrailing) {
                        Badge()
                    }
            }
            .padding(.horizontal)
        }
    }
}
