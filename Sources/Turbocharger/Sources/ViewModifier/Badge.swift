//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct BadgeModifier<Label: View>: ViewModifier {

    var alignment: Alignment
    var anchor: UnitPoint
    var scale: CGFloat
    var label: Label

    public init(
        alignment: Alignment,
        anchor: UnitPoint = UnitPoint(x: 0.25, y: 0.25),
        scale: CGFloat = 1.2,
        @ViewBuilder label: () -> Label
    ) {
        self.alignment = alignment
        self.anchor = anchor
        self.scale = scale
        self.label = label()
    }

    var badge: some View {
        label.alignmentGuideAdjustment(anchor: anchor)
    }

    public func body(content: Content) -> some View {
        content
            .invertedMask(alignment: alignment) {
                badge.scaleEffect(scale)
            }
            .overlay(badge, alignment: alignment)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension View {
    @inlinable
    public func badge<Label: View>(
        alignment: Alignment = .topTrailing,
        anchor: UnitPoint = UnitPoint(x: 0.25, y: 0.25),
        scale:  CGFloat = 1.2,
        @ViewBuilder label: () -> Label
    ) -> some View {
        modifier(
            BadgeModifier(
                alignment: alignment,
                anchor: anchor,
                label: label
            )
        )
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct BadgeModifier_Previews: PreviewProvider {
    struct Badge: View {
        var body: some View {
            Circle()
        }
    }

    static var previews: some View {
        VStack(spacing: 16) {
            HStack {
                Color.black
                    .frame(width: 44, height: 44)
                    .badge {
                        Badge()
                    }

                Color.black
                    .frame(width: 44, height: 44)
                    .badge(alignment: .bottomTrailing) {
                        Badge()
                    }

                Color.black
                    .frame(width: 44, height: 44)
                    .badge(alignment: .topLeading) {
                        Badge()
                    }

                Color.black
                    .frame(width: 44, height: 44)
                    .badge(alignment: .bottomLeading) {
                        Badge()
                    }
            }

            HStack {
                Circle()
                    .frame(width: 44, height: 44)
                    .badge {
                        Badge()
                    }

                Circle()
                    .frame(width: 44, height: 44)
                    .badge(alignment: .bottomTrailing) {
                        Badge()
                    }

                Circle()
                    .frame(width: 44, height: 44)
                    .badge(alignment: .topLeading) {
                        Badge()
                    }

                Circle()
                    .frame(width: 44, height: 44)
                    .badge(alignment: .bottomLeading) {
                        Badge()
                    }
            }

            HStack {
                Color.black
                    .frame(width: 100, height: 100)
                    .badge(alignment: .bottomTrailing) {
                        Color.blue
                            .frame(width: 40, height: 40)
                    }

                Circle()
                    .frame(width: 100, height: 100)
                    .badge(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 40, height: 40)
                    }
            }
        }
    }
}
