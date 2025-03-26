//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A view that arranges its subviews in a horizontal line a width
/// that is relative to its `LayoutWeightPriority`.
///
/// By default, all subviews will be arranged with equal width.
///
@frozen
public struct WeightedHStack<Content: View>: VersionedView {

    public var alignment: VerticalAlignment
    public var spacing: CGFloat?
    public var content: Content

    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var v4Body: some View {
        WeightedHStackLayout(alignment: alignment, spacing: spacing) {
            content
        }
    }

    @ViewBuilder
    public var v1Body: some View {
        let spacing = spacing ?? 8
        HStack(alignment: alignment, spacing: spacing) {
            content
        }
        .hidden()
        .overlay(
            GeometryReader { proxy in
                VariadicViewAdapter {
                    content
                } content: { source in
                    HStack(alignment: alignment, spacing: spacing) {
                        let children = source.children
                        let availableWidth = (proxy.size.width - (CGFloat(children.count - 1) * spacing))
                        let weights = children.reduce(into: 0) { value, subview in
                            value += max(0, min(subview.layoutWeightPriority, CGFloat(children.count)))
                        }
                        ForEach(children) { subview in
                            let weight = max(0, min(subview.layoutWeightPriority, CGFloat(children.count)))
                            let width = availableWidth * weight / weights
                            subview.frame(width: width)
                        }
                    }
                }
            }
        )
    }
}

/// A layout that arranges subviews in a horizontal line a width
/// that is relative to its `LayoutWeightPriority`.
///
/// By default, all subviews will be placed with equal width.
///
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct WeightedHStackLayout: Layout {

    public var alignment: VerticalAlignment
    public var spacing: CGFloat?

    public init(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let width = proposal.replacingUnspecifiedDimensions().width
        let spacing = spacing(subviews: subviews)
        let availableWidth = (width - spacing.reduce(0, +)) / CGFloat(subviews.count)

        var sizeThatFits: CGSize = subviews.reduce(into: .zero) { value, subview in
            let width = availableWidth * max(0, min(subview.layoutWeightPriority, Double(subviews.count)))
            let sizeThatFits = subview.sizeThatFits(
                ProposedViewSize(width: width, height: proposal.height)
            )
            value.height = max(value.height, sizeThatFits.height)
        }
        sizeThatFits.width = width
        return sizeThatFits
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        guard !subviews.isEmpty else { return }

        let weights = subviews.reduce(into: 0) { value, subview in
            value += max(0, min(subview.layoutWeightPriority, Double(subviews.count)))
        }
        let spacing = spacing(subviews: subviews)
        let availableWidth = bounds.width - spacing.reduce(0, +)

        let anchor: UnitPoint
        let y: CGFloat
        switch alignment {
        case .top:
            anchor = .top
            y = bounds.minY
        case .bottom:
            anchor = .bottom
            y = bounds.maxY
        default:
            anchor = .center
            y = bounds.midY
        }

        var x = bounds.minX
        for index in subviews.indices {
            let weight = min(subviews[index].layoutWeightPriority, Double(subviews.count))
            let width = availableWidth * max(0, weight) / max(weights, 1)
            x += width / 2
            let subviewProposal = ProposedViewSize(width: width, height: proposal.height)
            let placementProposal = ProposedViewSize(
                width: width,
                height: subviews[index].sizeThatFits(subviewProposal).height
            )
            if weight > 0 {
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: anchor,
                    proposal: placementProposal
                )
            } else {
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: anchor,
                    proposal: .zero
                )
            }
            x += width / 2 + spacing[index]
        }
    }

    private func spacing(subviews: Subviews) -> [CGFloat] {
        let spacing: [CGFloat] = {
            if let spacing = self.spacing {
                return Array(repeating: spacing, count: subviews.count - 1) + [0]
            }
            return subviews.indices.map { index in
                guard index < subviews.count - 1 else { return 0 }
                return subviews[index].spacing.distance(
                    to: subviews[index + 1].spacing,
                    along: .horizontal
                )
            }
        }()
        return spacing.indices.map { index in
            let weight = subviews[index].layoutWeightPriority
            if weight <= 0 {
                return 0
            }
            let hasNextNonZeroWeight = subviews[(index + 1)..<subviews.endIndex].contains {
                $0.layoutWeightPriority > 0
            }
            if hasNextNonZeroWeight {
                return spacing[index]
            }
            return 0
        }
    }

    public static var layoutProperties: LayoutProperties {
        HStackLayout.layoutProperties
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct WeightedHStackLayout_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WeightedHStack(spacing: 24) {
                Color.yellow
                    .layoutWeight(0)

                Color.yellow
                    .layoutWeight(0)

                Color.red

                Color.yellow
                    .layoutWeight(0)

                Color.yellow
                    .layoutWeight(0)

                Color.blue

                Color.yellow
                    .layoutWeight(0)

                Color.yellow
                    .layoutWeight(0)
            }

            WeightedHStack(spacing: 24) {
                Color.red

                Color.yellow
                    .layoutWeight(.infinity)

                Color.blue
            }

            WeightedHStack(spacing: 24) {
                Color.red

                Color.yellow
                    .layoutWeight(.infinity)

                Color.yellow
                    .layoutWeight(.infinity)

                Color.blue
            }

            WeightedHStack(spacing: 24) {
                Color.red

                Color.yellow
                    .layoutWeight(2)

                Color.blue
            }

            WeightedHStack(spacing: 24) {
                Color.red
                    .layoutWeight(2)

                Color.yellow
                    .layoutWeight(0.5)

                Color.blue
            }
        }
        .padding(24)

        HStack(spacing: 12) {
            Button {
            } label: {
                Text("Primary")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background {
                        Capsule()
                            .fill(.tertiary)
                    }
            }

            WeightedHStack(spacing: 12) {
                Button {
                } label: {
                    Text("Action A")
                        .padding()
                        .background {
                            Capsule()
                                .fill(.tertiary)
                        }
                }

                Button {
                } label: {
                    Text("Action B")
                        .padding()
                        .background {
                            Capsule()
                                .fill(.tertiary)
                        }
                }
            }
        }
        .lineLimit(1)
        .previewDisplayName("Buttons")

        VStack {
            HStack {
                ForEach(0..<3, id: \.self) { _ in
                    Color.yellow
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .background(Color.blue)

            WeightedHStack {
                ForEach(0..<3, id: \.self) { _ in
                    Color.yellow
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .background(Color.red)
        }
        .previewDisplayName("Aspect Ratio")

        WeightedHStack {
            Text("Line 1")

            Text("Line 2")
                .layoutWeight(2)

            Text("Line 3")
        }
        .background(Color.blue)
        .previewDisplayName("Text")
    }
}
