//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A view that arranges its subviews along multiple horizontal lines.
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct FlowStack<Content: View>: View {

    public var alignment: Alignment
    public var columnSpacing: CGFloat?
    public var rowSpacing: CGFloat?
    public var content: Content

    public init(
        alignment: Alignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            alignment: alignment,
            columnSpacing: spacing,
            rowSpacing: spacing,
            content: content
        )
    }

    public init(
        alignment: Alignment = .center,
        columnSpacing: CGFloat? = nil,
        rowSpacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.columnSpacing = columnSpacing
        self.rowSpacing = rowSpacing
        self.content = content()
    }

    public var body: some View {
        FlowStackLayout(
            alignment: alignment,
            columnSpacing: columnSpacing,
            rowSpacing: rowSpacing,
        ) {
            content
        }
    }
}

/// A layout that arranges subviews along multiple horizontal lines.
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct FlowStackLayout: Layout {

    public var alignment: Alignment = .center
    public var columnSpacing: CGFloat?
    public var rowSpacing: CGFloat?

    public init(
        alignment: Alignment,
        spacing: CGFloat? = nil
    ) {
        self.init(
            alignment: alignment,
            columnSpacing: spacing,
            rowSpacing: spacing
        )
    }

    public init(
        alignment: Alignment,
        columnSpacing: CGFloat? = nil,
        rowSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment
        self.columnSpacing = columnSpacing
        self.rowSpacing = rowSpacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let layoutProposal = layoutProposal(
            subviews: subviews,
            proposal: proposal
        )
        return layoutProposal.frames.union.size
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let layoutProposal = layoutProposal(
            subviews: subviews,
            proposal: proposal
        )
        for (frame, subview) in zip(layoutProposal.frames, subviews) {
            subview.place(
                at: CGPoint(
                    x: frame.origin.x + bounds.minX,
                    y: frame.origin.y + bounds.minY
                ),
                proposal: .init(frame.size)
            )
        }
    }

    private struct LayoutProposal {
        var frames: [CGRect]
    }
    private func layoutProposal(
        subviews: Subviews,
        proposal: ProposedViewSize,
    ) -> LayoutProposal {

        var result: [CGRect] = []
        var currentPosition: CGPoint = .zero
        var currentLine: [CGRect] = []
        let maxWidth = proposal.replacingUnspecifiedDimensions().width

        func endLine(index: Subviews.Index) {
            let union = currentLine.union
            result.append(contentsOf: currentLine.map { rect in
                var copy = rect
                copy.origin.y += currentPosition.y - union.minY
                return copy
            })

            currentPosition.x = 0
            currentPosition.y += union.height
            if index < subviews.endIndex {
                let spacing = rowSpacing ?? subviews[index - 1].spacing.distance(
                    to: subviews[index].spacing,
                    along: .vertical
                )
                currentPosition.y += spacing
            }
            currentLine.removeAll()
        }

        for index in subviews.indices {
            let dimension = subviews[index].dimensions(in: proposal)
            if index > 0 {
                let spacing = columnSpacing ?? subviews[index - 1].spacing.distance(
                    to: subviews[index].spacing,
                    along: .horizontal
                )
                currentPosition.x += spacing

                if currentPosition.x + dimension.width > maxWidth {
                    endLine(index: index)
                }
            }

            currentLine.append(
                CGRect(
                    x: currentPosition.x,
                    y: -dimension[alignment.vertical],
                    width: dimension.width,
                    height: dimension.height
                )
            )
            currentPosition.x += dimension.width
        }
        endLine(index: subviews.endIndex)

        return LayoutProposal(
            frames: result
        )
    }

    public static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .vertical
        return properties
    }
}

extension Sequence where Element == CGRect {
    var union: CGRect {
        reduce(.null, { $0.union($1) })
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct FlowStack_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var width: CGFloat = 350

        var body: some View {
            VStack {
                Text(width.rounded().description)
                #if os(iOS) || os(macOS)
                Slider(value: $width, in: 10...375)
                #endif

                FlowStack {
                    ScrollView {
                        VStack(alignment: .center, spacing: 24) {
                            FlowStack {
                                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")

                                Divider()

                                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
                            }


                            FlowStack(
                                alignment: Alignment(horizontal: .center, vertical: .firstTextBaseline)
                            ) {
                                let words = "elit sed vulputate mi sit amet mauris commodo quis imperdiet"
                                ForEach(words.components(separatedBy: .whitespaces), id: \.self) { word in
                                    Text(word)
                                        .font(word.count.isMultiple(of: 2) ? .title : .body)
                                }

                                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")

                                Text("Hello World")

                                Divider()

                                Text("Hello World")
                                    .font(.title)
                            }

                            FlowStack(alignment: .center) {
                                ForEach(1..<5) { num in
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

                            FlowStack(
                                alignment: .trailing,
                                columnSpacing: 12,
                                rowSpacing: 4
                            ) {
                                ForEach(1..<16) { num in
                                    Text(String(num))
                                        .frame(minWidth: 30, minHeight: 30)
                                        .background(Circle().fill(Color.red))
                                }
                            }
                        }
                        .frame(width: width)
                    }
                }
            }
            .padding()
        }
    }
}
