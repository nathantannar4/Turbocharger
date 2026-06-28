//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A view that arranges its subviews along multiple horizontal lines.
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct MasonryStack<
    Content: View
>: View {

    public var columns: Int
    public var spacing: CGFloat
    public var content: Content

    public init(
        columns: Int,
        spacing: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.columns = columns
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        MasonryLayout(columns: columns, spacing: spacing) {
            content
        }
    }
}

@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct MasonryLayout: Layout {

    public var columns: Int
    public var spacing: CGFloat

    public init(
        columns: Int,
        spacing: CGFloat
    ) {
        self.columns = columns
        self.spacing = spacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let subviews = subviews.sorted(by: { $0.priority > $1.priority })
        let layoutProposal = layoutProposal(
            subviews: subviews,
            proposal: proposal,
            cache: &cache
        )
        return layoutProposal.frame.size
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let subviews = subviews.sorted(by: { $0.priority > $1.priority })
        let layoutProposal = layoutProposal(
            subviews: subviews,
            proposal: proposal,
            cache: &cache
        )
        for index in subviews.indices {
            let frame = layoutProposal.frames[index]!
            subviews[index].place(
                at: CGPoint(
                    x: frame.origin.x + bounds.minX,
                    y: frame.origin.y + bounds.minY
                ),
                proposal: .init(frame.size)
            )
        }
    }

    struct LayoutProposal {
        var frames: [LayoutSubviews.Index: CGRect] = [:]

        var frame: CGRect {
            frames.map({ $0.value }).union
        }
    }

    private func layoutProposal(
        subviews: [LayoutSubview],
        proposal: ProposedViewSize,
        cache: inout Cache
    ) -> LayoutProposal {

        if let layoutProposal = cache.layoutProposal,
            cache.proposedSize == proposal
        {
            return layoutProposal
        }

        var layoutProposal = LayoutProposal()
        let width = proposal.replacingUnspecifiedDimensions().width
        let totalSpacing = spacing * CGFloat(columns - 1)
        let columnWidth = max(0, (width - totalSpacing) / CGFloat(columns))
        var columnHeights = [CGFloat](repeating: 0, count: columns)

        for index in subviews.indices {
            let dimensions = subviews[index].dimensions(
                in: ProposedViewSize(
                    width: columnWidth,
                    height: nil
                )
            )

            var column = 0
            for col in 1..<columns where columnHeights[col] < columnHeights[column] {
                column = col
            }

            let y = columnHeights[column]
            layoutProposal.frames[index] = CGRect(
                x: CGFloat(column) * (columnWidth + spacing),
                y: y,
                width: columnWidth,
                height: dimensions.height
            )

            columnHeights[column] += dimensions.height + spacing
        }

        cache.proposedSize = proposal
        cache.layoutProposal = layoutProposal
        return layoutProposal
    }

    public struct Cache {
        var proposedSize: ProposedViewSize?
        var layoutProposal: LayoutProposal?
    }

    public func makeCache(
        subviews: Subviews
    ) -> Cache {
        Cache()
    }

    public func updateCache(
        _ cache: inout Cache,
        subviews: Subviews
    ) {
        cache = Cache()
    }

    public static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .vertical
        return properties
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct MasonryStack_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {

        @State var columns = 2
        @State var count = 16

        var body: some View {
            ScrollView {
                MasonryStack(
                    columns: columns,
                    spacing: 8
                ) {
                    ForEach(0..<count, id: \.self) { index in
                        Color.blue
                            .frame(height: index.isMultiple(of: 3) ? 50 : 100)
                            .overlay {
                                Text(index.description)
                                    .foregroundColor(.white)
                            }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                VStack {
                    HStack {
                        Button("Remove Column") {
                            withAnimation {
                                columns -= 1
                            }
                        }

                        Button("Add Column") {
                            withAnimation {
                                columns += 1
                            }
                        }
                    }

                    HStack {
                        Button("Remove Item") {
                            withAnimation {
                                count -= 1
                            }
                        }

                        Button("Add Item") {
                            withAnimation {
                                count += 1
                            }
                        }
                    }
                }
            }
        }
    }
}
