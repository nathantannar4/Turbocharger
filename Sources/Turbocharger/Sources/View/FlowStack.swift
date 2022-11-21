//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A view that arranges its subviews along multiple horizontal lines.
///
/// > Warning: Version 4+ is required for non-leading alignment
@frozen
public struct FlowStack<Content: View>: VersionedView {

    public var alignment: Alignment
    public var spacing: CGFloat?
    public var content: Content

    public init(
        alignment: Alignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var v4Body: some View {
        FlowStackLayout(alignment: alignment, spacing: spacing) {
            content
        }
    }

    public var v1Body: some View {
        let spacing = spacing ?? 8
        ZStack(alignment: alignment) {
            var width: CGFloat = 0
            var x: CGFloat = 0
            var y: CGFloat = 0

            Color.clear
                .frame(height: 0)
                .hidden()
                .alignmentGuide(alignment.horizontal) { d in
                    width = d.width
                    x = 0
                    y = 0
                    return 0
                }

            content
                .alignmentGuide(alignment.horizontal) { d in
                    if x + d.width > width {
                        x = 0
                        y += d.height + spacing
                    }

                    let result = x
                    x += d.width + spacing
                    return -result
                }
                .alignmentGuide(alignment.vertical) { _ in
                    -y
                }
        }
    }
}

/// A layout that arranges subviews along multiple horizontal lines.
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct FlowStackLayout: Layout {

    public var alignment: Alignment = .center
    public var spacing: CGFloat?

    public init(
        alignment: Alignment,
        spacing: CGFloat? = nil
    ) {
        self.alignment = alignment
        self.spacing = spacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            alignment: alignment,
            spacing: spacing
        )
        return result.bounds
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            alignment: alignment,
            spacing: spacing
        )
        for row in result.rows {
            let rowXOffset = (bounds.width - row.frame.width) * alignment.horizontal.percent
            for index in row.range {
                let xPos = rowXOffset + row.frame.minX + row.xOffsets[index - row.range.lowerBound] + bounds.minX
                let rowYAlignment = (row.frame.height - subviews[index].sizeThatFits(.unspecified).height) *
                alignment.vertical.percent
                let yPos = row.frame.minY + rowYAlignment + bounds.minY
                subviews[index].place(at: CGPoint(x: xPos, y: yPos), anchor: .topLeading, proposal: .unspecified)
            }
        }
    }

    struct FlowResult {
        var bounds = CGSize.zero
        var rows = [Row]()

        struct Row {
            var range: Range<Int>
            var xOffsets: [Double]
            var frame: CGRect
        }

        init(
            in maxPossibleWidth: Double,
            subviews: Subviews,
            alignment: Alignment,
            spacing: CGFloat?
        ) {
            func spacingBefore(index: Int) -> Double {
                guard itemsInRow > 0 else { return 0 }
                return spacing ?? subviews[index - 1].spacing.distance(to: subviews[index].spacing, along: .horizontal)
            }

            func widthInRow(index: Int, idealWidth: Double) -> Double {
                idealWidth + spacingBefore(index: index)
            }

            func addToRow(index: Int, idealSize: CGSize) {
                let width = widthInRow(index: index, idealWidth: idealSize.width)

                xOffsets.append(maxPossibleWidth - remainingWidth + spacingBefore(index: index))
                // Allocate width to this item (and spacing).
                remainingWidth -= width
                // Ensure the row height is as tall as the tallest item.
                rowHeight = max(rowHeight, idealSize.height)
                // Can fit in this row, add it.
                itemsInRow += 1
            }

            func finalizeRow(index: Int, idealSize: CGSize) {
                let rowWidth = maxPossibleWidth - remainingWidth
                rows.append(
                    Row(
                        range: index - max(itemsInRow - 1, 0) ..< index + 1,
                        xOffsets: xOffsets,
                        frame: CGRect(x: 0, y: rowMinY, width: rowWidth, height: rowHeight)
                    )
                )
                bounds.width = max(bounds.width, rowWidth)
                let ySpacing = spacing ?? ViewSpacing().distance(to: ViewSpacing(), along: .vertical)
                bounds.height += rowHeight + (rows.count > 1 ? ySpacing : 0)
                rowMinY += rowHeight + ySpacing
                itemsInRow = 0
                rowHeight = 0
                xOffsets.removeAll()
                remainingWidth = maxPossibleWidth
            }

            var itemsInRow = 0
            var remainingWidth = maxPossibleWidth.isFinite ? maxPossibleWidth : .greatestFiniteMagnitude
            var rowMinY = 0.0
            var rowHeight = 0.0
            var xOffsets: [Double] = []
            for (index, subview) in zip(subviews.indices, subviews) {
                let idealSize = subview.sizeThatFits(.unspecified)
                if index != 0 && widthInRow(index: index, idealWidth: idealSize.width) > remainingWidth {
                    // Finish the current row without this subview.
                    finalizeRow(index: max(index - 1, 0), idealSize: idealSize)
                }
                addToRow(index: index, idealSize: idealSize)

                if index == subviews.count - 1 {
                    // Finish this row; it's either full or we're on the last view anyway.
                    finalizeRow(index: index, idealSize: idealSize)
                }
            }
            if alignment.horizontal != .center {
                bounds.width = maxPossibleWidth
            }
        }
    }
}

extension HorizontalAlignment {
    fileprivate var percent: Double {
        switch self {
        case .leading:
            return 0
        case .trailing:
            return 1
        default:
            return 0.5
        }
    }
}

extension VerticalAlignment {
    fileprivate var percent: Double {
        switch self {
        case .top:
            return 0
        case .bottom:
            return 1
        default:
            return 0.5
        }
    }
}

struct FlowStack_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            FlowStack(alignment: .trailing) {
                ForEach(1..<6) { num in
                    Text(String(num))
                        .frame(minWidth: 30, minHeight: 30)
                        .background(Circle().fill(Color.red))
                }
            }

            FlowStack(alignment: .leading) {
                ForEach(1..<18) { num in
                    Text(String(num))
                        .frame(minWidth: 30, minHeight: 30)
                        .background(Circle().fill(Color.red))
                }
            }

            FlowStack(alignment: .center) {
                ForEach(1..<23) { num in
                    Text(String(num))
                        .frame(minWidth: 30, minHeight: 30)
                        .background(Circle().fill(Color.red))
                }
            }

            FlowStack(alignment: .trailing) {
                ForEach(1..<16) { num in
                    Text(String(num))
                        .frame(minWidth: 30, minHeight: 30)
                        .background(Circle().fill(Color.red))
                }
            }
        }
    }
}
