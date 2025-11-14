//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A modifier that adds a view as a badge
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@frozen
public struct BadgeModifier<
    Label: View,
    Mask: View
>: ViewModifier {

    public var alignment: Alignment
    public var anchor: UnitPoint
    public var label: Label
    public var mask: Mask

    @inlinable
    public init(
        alignment: Alignment,
        anchor: UnitPoint = UnitPoint(x: 0.25, y: 0.25),
        scale: CGPoint = CGPoint(x: 1, y: 1),
        inset: EdgeInsets = .zero,
        @ViewBuilder label: () -> Label
    ) where Mask == BadgeMask<Label> {
        self.alignment = alignment
        self.anchor = anchor
        self.label = label()
        self.mask = BadgeMask(
            scale: scale,
            inset: inset,
            label: label
        )
    }

    @_disfavoredOverload
    @inlinable
    public init(
        alignment: Alignment,
        anchor: UnitPoint = UnitPoint(x: 0.25, y: 0.25),
        scale: CGFloat = 1,
        inset: CGFloat = 0,
        @ViewBuilder label: () -> Label
    ) where Mask == BadgeMask<Label> {
        self.alignment = alignment
        self.anchor = anchor
        self.label = label()
        self.mask = BadgeMask(
            scale: scale,
            inset: inset,
            label: label
        )
    }

    @inlinable
    public init(
        alignment: Alignment,
        anchor: UnitPoint = UnitPoint(x: 0.25, y: 0.25),
        @ViewBuilder label: () -> Label,
        @ViewBuilder mask: () -> Mask
    )  {
        self.alignment = alignment
        self.anchor = anchor
        self.label = label()
        self.mask = mask()
    }

    public func body(content: Content) -> some View {
        content
            .invertedMask(alignment: alignment) {
                mask.alignmentGuideAdjustment(anchor: anchor)
            }
            .overlay(
                label.alignmentGuideAdjustment(anchor: anchor),
                alignment: alignment
            )
    }
}

@frozen
public struct BadgeMask<Label: View>: View {

    public var scale: CGPoint
    public var inset: EdgeInsets
    public var label: Label

    @inlinable
    init(
        scale: CGPoint = CGPoint(x: 1, y: 1),
        inset: EdgeInsets = .zero,
        @ViewBuilder label: () -> Label
    ) {
        self.scale = scale
        self.inset = inset
        self.label = label()
    }

    @_disfavoredOverload
    @inlinable
    init(
        scale: CGFloat = 1,
        inset: CGFloat = 0,
        @ViewBuilder label: () -> Label
    ) {
        self.init(
            scale: CGPoint(x: scale, y: scale),
            inset: .uniform(inset),
            label: label
        )
    }

    public var body: some View {
        label
            .modifier(
                TransformEffect(scale: scale, inset: inset)
            )
    }

    private struct TransformEffect: GeometryEffect {
        var scale: CGPoint
        var inset: EdgeInsets

        func effectValue(size: CGSize) -> ProjectionTransform {
            let dx = scale.x * (size.width + inset.horizontal) / size.width
            let dy = scale.y * (size.height + inset.vertical) / size.height
            let x = size.width * (dx - 1) / 2
            let y = size.height * (dy - 1) / 2
            return ProjectionTransform(
                CGAffineTransform(translationX: -x, y: -y)
                    .scaledBy(x: dx, y: dy)
            )
        }
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
        inset: EdgeInsets = .zero,
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
    public func badge<
        Label: View,
        Mask: View
    >(
        alignment: Alignment = .topTrailing,
        anchor: UnitPoint = UnitPoint(x: 0.25, y: 0.25),
        @ViewBuilder label: () -> Label,
        @ViewBuilder mask: () -> Mask
    ) -> some View {
        modifier(
            BadgeModifier(
                alignment: alignment,
                anchor: anchor,
                label: label,
                mask: mask
            )
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

            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 80, height: 80)
                    .badge(alignment: .bottom, anchor: .center, inset: 4) {
                        Badge()
                    }

                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 80, height: 80)
                    .badge(alignment: .bottom, anchor: .center, scale: 1.25) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                    }
            }
            .padding(.horizontal)

            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 80, height: 80)
                    .badge(
                        alignment: .bottom,
                        anchor: .center
                    ) {
                        Text("Lorum")
                    } mask: {
                        BadgeMask(
                            inset: .horizontal(8) + .vertical(4)
                        ) {
                            Badge()
                        }
                    }

                #if canImport(FoundationModels)
                if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
                    // Glass effect doesn't work with default masking
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: 80, height: 80)
                        .badge(
                            alignment: .bottom,
                            anchor: .center
                        ) {
                            Text("Lorum")
                                .foregroundStyle(.white)
                                .padding(4)
                                .glassEffect(.regular.tint(.blue), in: Capsule())
                        }

                    // Specify a custom mask
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: 80, height: 80)
                        .badge(
                            alignment: .bottom,
                            anchor: .center
                        ) {
                            Text("Lorum")
                                .foregroundStyle(.white)
                                .padding(4)
                                .glassEffect(.regular.tint(.blue), in: Capsule())
                        } mask: {
                            BadgeMask(
                                inset: .horizontal(8) + .vertical(4) + .uniform(4)
                            ) {
                                Badge()
                            }
                        }
                }
                #endif
            }
        }
    }
}
