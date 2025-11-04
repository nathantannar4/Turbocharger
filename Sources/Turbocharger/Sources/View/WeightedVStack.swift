//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A view that arranges its subviews in a vertical line a height
/// that is relative to its `LayoutWeightPriority`.
///
/// By default, all subviews will be arranged with equal height.
///
@frozen
public struct WeightedVStack<Content: View>: VersionedView {

    public var alignment: HorizontalAlignment
    public var spacing: CGFloat?
    public var content: Content

    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var v4Body: some View {
        WeightedVStackLayout(alignment: alignment, spacing: spacing) {
            content
        }
    }

    @ViewBuilder
    public var v1Body: some View {
        let spacing = spacing ?? 8
        VStack(alignment: alignment, spacing: spacing) {
            content
        }
        .hidden()
        .overlay(
            GeometryReader { proxy in
                VariadicViewAdapter {
                    content
                } content: { children in
                    VStack(alignment: alignment, spacing: spacing) {
                        let availableHeight = (proxy.size.height - (CGFloat(children.count - 1) * spacing))
                        let weights = children.reduce(into: 0) { value, subview in
                            value += max(0, min(subview.layoutWeightPriority, CGFloat(children.count)))
                        }
                        ForEach(children) { subview in
                            let weight = max(0, min(subview.layoutWeightPriority, CGFloat(children.count)))
                            let height = availableHeight * weight / weights
                            subview.frame(height: height)
                        }
                    }
                }
            }
        )
    }
}

/// A layout that arranges subviews in a vertical line a height
/// that is relative to its `LayoutWeightPriority`.
///
/// By default, all subviews will be placed with equal height.
///
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct WeightedVStackLayout: Layout {

    public var alignment: HorizontalAlignment
    public var spacing: CGFloat?

    public init(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let height = proposal.replacingUnspecifiedDimensions().height
        let spacing = spacing(subviews: subviews)
        let availableHeight = (height - spacing.reduce(0, +)) / CGFloat(subviews.count)

        var sizeThatFits: CGSize = subviews.reduce(into: .zero) { value, subview in
            let height = availableHeight * max(0, min(subview.layoutWeightPriority, Double(subviews.count)))
            let sizeThatFits = subview.sizeThatFits(
                ProposedViewSize(width: proposal.width, height: height)
            )
            value.width = max(value.width, sizeThatFits.width)
        }
        sizeThatFits.height = height
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
        let availableHeight = bounds.height - spacing.reduce(0, +)

        let anchor: UnitPoint
        let x: CGFloat
        switch alignment {
        case .leading:
            anchor = .leading
            x = bounds.minX
        case .trailing:
            anchor = .trailing
            x = bounds.maxX
        default:
            anchor = .center
            x = bounds.midX
        }

        var y = bounds.minY
        for index in subviews.indices {
            let weight = min(subviews[index].layoutWeightPriority, Double(subviews.count))
            let height = availableHeight * max(0, weight) / max(weights, 1)

            y += height / 2
            if weight > 0 {
                let subviewProposal = ProposedViewSize(width: proposal.width, height: height)
                let placementProposal = ProposedViewSize(
                    width: subviews[index].sizeThatFits(subviewProposal).width,
                    height: height
                )
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
            y += height / 2 + spacing[index]
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
        VStackLayout.layoutProperties
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct WeightedVStackLayout_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            WeightedVStack(spacing: 24) {
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

            WeightedVStack(spacing: 24) {
                Color.red

                Color.yellow
                    .layoutWeight(.infinity)

                Color.blue
            }

            WeightedVStack(spacing: 24) {
                Color.red

                Color.yellow
                    .layoutWeight(.infinity)

                Color.yellow
                    .layoutWeight(.infinity)

                Color.blue
            }

            WeightedVStack(spacing: 24) {
                Color.red

                Color.yellow
                    .layoutWeight(2)

                Color.blue
            }

            WeightedVStack(spacing: 24) {
                Color.red
                    .layoutWeight(2)

                Color.yellow
                    .layoutWeight(0.5)

                Color.blue
            }
        }
        .padding(24)

        HStack {
            VStack {
                ForEach(0..<3, id: \.self) { _ in
                    Color.yellow
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .background(Color.blue)

            WeightedVStack {
                ForEach(0..<3, id: \.self) { _ in
                    Color.yellow
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .background(Color.red)
        }
        .previewDisplayName("Aspect Ratio")

        HStack {
            WeightedVStack(alignment: .leading) {
                Text("Line 1")

                Text("Line 2")

                Text("Line 3")
            }
            .background(Color.blue)

            VStack(alignment: .leading) {
                Text("Line 1")

                Text("Line 2")

                Text("Line 3")
            }
            .background(Color.blue)
        }
        .previewDisplayName("Text")
    }
}
