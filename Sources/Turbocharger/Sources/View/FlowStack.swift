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
                .alignmentGuide(alignment.vertical) { d in
                    d.height - y
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
        let layoutProposal = layoutProposal(
            subviews: subviews,
            spacing: spacing,
            proposal: proposal,
            alignment: alignment
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
            spacing: spacing,
            proposal: proposal,
            alignment: alignment
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
        spacing: CGFloat?,
        proposal: ProposedViewSize,
        alignment: Alignment
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
                let spacing = spacing ?? subviews[index - 1].spacing.distance(
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
                let spacing = spacing ?? subviews[index - 1].spacing.distance(
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

struct FlowStack_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var width: CGFloat = 350

        var body: some View {
            VStack {
                Text(width.rounded().description)
                Slider(value: $width, in: 10...375)

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

                            FlowStack(alignment: .trailing) {
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
