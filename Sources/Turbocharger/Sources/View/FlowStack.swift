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
    public var options: FlowStackLayout.Options
    public var columnSpacing: CGFloat?
    public var rowSpacing: CGFloat?
    public var minimumNumberOfRows: Int?
    public var content: Content

    public init(
        alignment: Alignment = .center,
        options: FlowStackLayout.Options = [],
        spacing: CGFloat? = nil,
        minimumNumberOfRows: Int? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            alignment: alignment,
            options: options,
            columnSpacing: spacing,
            rowSpacing: spacing,
            minimumNumberOfRows: minimumNumberOfRows,
            content: content
        )
    }

    public init(
        alignment: Alignment = .center,
        options: FlowStackLayout.Options = [],
        columnSpacing: CGFloat? = nil,
        rowSpacing: CGFloat? = nil,
        minimumNumberOfRows: Int? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.options = options
        self.columnSpacing = columnSpacing
        self.rowSpacing = rowSpacing
        self.minimumNumberOfRows = minimumNumberOfRows
        self.content = content()
    }

    public var body: some View {
        FlowStackLayout(
            alignment: alignment,
            options: options,
            columnSpacing: columnSpacing,
            rowSpacing: rowSpacing,
            minimumNumberOfRows: minimumNumberOfRows
        ) {
            content
        }
    }
}

/// A layout that arranges subviews along multiple horizontal lines.
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct FlowStackLayout: Layout {

    @frozen
    public struct Options: OptionSet, Sendable {
        public var rawValue: UInt8
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public static let fill = Options(rawValue: 1 << 0)
    }

    public var alignment: Alignment = .center
    public var options: Options
    public var columnSpacing: CGFloat?
    public var rowSpacing: CGFloat?
    public var minimumNumberOfRows: Int?

    public init(
        alignment: Alignment,
        options: Options = [],
        spacing: CGFloat? = nil,
        minimumNumberOfRows: Int? = nil
    ) {
        self.init(
            alignment: alignment,
            options: options,
            columnSpacing: spacing,
            rowSpacing: spacing,
            minimumNumberOfRows: minimumNumberOfRows
        )
    }

    public init(
        alignment: Alignment,
        options: Options = [],
        columnSpacing: CGFloat? = nil,
        rowSpacing: CGFloat? = nil,
        minimumNumberOfRows: Int?
    ) {
        self.alignment = alignment
        self.options = options
        self.columnSpacing = columnSpacing
        self.rowSpacing = rowSpacing
        self.minimumNumberOfRows = minimumNumberOfRows
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let subviews = subviews.sorted(by: { $0.priority > $1.priority })
        let layoutProposal = layoutProposal(
            subviews: subviews,
            proposal: proposal
        )
        return layoutProposal.frame.size
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let subviews = subviews.sorted(by: { $0.priority > $1.priority })
        let layoutProposal = layoutProposal(
            subviews: subviews,
            proposal: proposal
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

    private struct LayoutProposalLine {
        var frames: [LayoutSubviews.Index: CGRect] = [:]

        var frame: CGRect {
            frames.map({ $0.value }).union
        }
    }
    private struct LayoutProposal {
        var lines: [LayoutProposalLine] = []

        var frames: [LayoutSubviews.Index: CGRect] {
            lines.reduce(into: [:]) { result, line in
                result.merge(line.frames, uniquingKeysWith: { lhs, _ in lhs })
            }
        }

        var frame: CGRect {
            frames.map({ $0.value }).union
        }
    }

    private func layoutProposal(
        subviews: [LayoutSubview],
        proposal: ProposedViewSize
    ) -> LayoutProposal {

        var layoutProposal = LayoutProposal()
        var currentX: CGFloat = 0
        var currentLine = LayoutProposalLine()
        let maxWidth = proposal.width ?? .infinity
        let minimumNumberOfRows = minimumNumberOfRows ?? 0

        func endLine(index: Subviews.Index) {
            layoutProposal.lines.append(currentLine)
            currentX = 0
            currentLine = LayoutProposalLine()
        }

        for index in subviews.indices {
            let dimension = subviews[index].dimensions(in: proposal)
            var needsLayout = true
            if !currentLine.frames.isEmpty {
                let spacing = columnSpacing ?? subviews[index - 1].spacing.distance(
                    to: subviews[index].spacing,
                    along: .horizontal
                )
                if layoutProposal.lines.count < (minimumNumberOfRows - 1) {
                    endLine(index: index)
                } else if currentX + spacing + dimension.width > maxWidth {
                    if options.contains(.fill), layoutProposal.lines.count > 0 {
                        for lineIndex in layoutProposal.lines.indices {
                            let line = layoutProposal.lines[lineIndex]
                            let spacing = columnSpacing ?? {
                                let fromIndex = line.frames
                                    .max(by: { $0.value.maxX > $1.value.maxX })?
                                    .key ?? (index - 1)
                                return subviews[fromIndex].spacing.distance(
                                    to: subviews[index].spacing,
                                    along: .horizontal
                                )
                            }()
                            let x = line.frame.maxX + spacing
                            if x + dimension.width <= maxWidth {
                                let rect = CGRect(
                                    x: x,
                                    y: -dimension[alignment.vertical],
                                    width: dimension.width,
                                    height: dimension.height
                                )
                                layoutProposal.lines[lineIndex].frames[index] = rect
                                needsLayout = false
                                break
                            }
                        }
                    }
                    endLine(index: index)
                } else if minimumNumberOfRows > 0 {
                    let lines = (layoutProposal.lines + [currentLine])
                    var enumeratedLines = Array(zip(lines.indices, lines))
                    if !options.contains(.fill) {
                        enumeratedLines = Array(enumeratedLines.sorted(by: { $0.1.frame.maxX < $1.1.frame.maxX }))
                    }
                    for (lineIndex, line) in enumeratedLines {
                        let spacing = columnSpacing ?? {
                            let fromIndex = line.frames
                                .max(by: { $0.value.maxX > $1.value.maxX })?
                                .key ?? (index - 1)
                            return subviews[fromIndex].spacing.distance(
                                to: subviews[index].spacing,
                                along: .horizontal
                            )
                        }()
                        let x = line.frame.maxX + spacing
                        if x + dimension.width <= maxWidth {
                            let rect = CGRect(
                                x: x,
                                y: -dimension[alignment.vertical],
                                width: dimension.width,
                                height: dimension.height
                            )
                            if lineIndex < layoutProposal.lines.count {
                                layoutProposal.lines[lineIndex].frames[index] = rect
                                needsLayout = false
                            }
                            break
                        }
                    }
                    if needsLayout {
                        currentX += spacing
                    }
                } else {
                    currentX += spacing
                }
            }

            if needsLayout {
                let rect = CGRect(
                    x: currentX,
                    y: -dimension[alignment.vertical],
                    width: dimension.width,
                    height: dimension.height
                )
                currentLine.frames[index] = rect
                currentX += dimension.width
            }
        }
        if !currentLine.frames.isEmpty {
            endLine(index: subviews.endIndex)
        }

        var currentY: CGFloat = 0
        for lineIndex in layoutProposal.lines.indices {
            let line = layoutProposal.lines[lineIndex]
            if lineIndex > 0 {
                let spacing = rowSpacing ?? {
                    var minSpacing: CGFloat = 0
                    let fromIndex = layoutProposal.lines[lineIndex - 1].frames
                        .max(by: { $0.value.maxY > $1.value.maxY })?
                        .key ?? 0
                    for index in line.frames.keys {
                        let spacing = subviews[fromIndex].spacing.distance(
                            to: subviews[index].spacing,
                            along: .vertical
                        )
                        minSpacing = max(minSpacing, spacing)
                    }
                    return minSpacing
                }()
                currentY += spacing
            }

            let union = line.frame
            layoutProposal.lines[lineIndex].frames = line.frames.mapValues { rect in
                var newValue = rect
                newValue.origin.y -= union.midY
                newValue.origin.y += union.height / 2
                newValue.origin.y += currentY
                if layoutProposal.lines.count > 0 {
                    switch alignment.horizontal {
                    case .leading:
                        break
                    case .trailing:
                        let delta = layoutProposal.frame.width - union.width
                        newValue.origin.x += delta
                    case .center:
                        let delta = layoutProposal.frame.width - union.width
                        newValue.origin.x += delta / 2
                    default:
                        break
                    }
                }
                return newValue
            }
            currentY += layoutProposal.lines[lineIndex].frame.height
        }

        return layoutProposal
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
        Preview1()
        Preview2()
        Preview3()
    }

    struct Preview1: View {
        var body: some View {
            VStack(alignment: .center, spacing: 8) {
                Text("Alignment / Layout Priority")
                    .font(.title)

                let head = Text(verbatim: "0")
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Circle().fill(Color.green))
                    .layoutPriority(1)
                let tail = Text(verbatim: "18")
                    .frame(minWidth: 40, minHeight: 40)
                    .background(Circle().fill(Color.red))
                    .layoutPriority(-1)
                let list = ForEach(1..<18) { num in
                    Text(String(num))
                        .frame(minWidth: 30, minHeight: 30)
                        .background(Circle().fill(Color.blue))
                }

                VStack(spacing: 24) {
                    FlowStack(alignment: .center) {
                        tail

                        ForEach(1..<5) { num in
                            Text(String(num))
                                .frame(minWidth: 30, minHeight: 30)
                                .background(Circle().fill(Color.blue))
                        }

                        head
                    }
                    .border(Color.gray)

                    FlowStack(alignment: .top) {
                        tail

                        ForEach(1..<5) { num in
                            Text(String(num))
                                .frame(minWidth: 30, minHeight: 30)
                                .background(Circle().fill(Color.blue))
                        }

                        head
                    }
                    .border(Color.gray)

                    FlowStack(alignment: .bottom) {
                        tail

                        ForEach(1..<5) { num in
                            Text(String(num))
                                .frame(minWidth: 30, minHeight: 30)
                                .background(Circle().fill(Color.blue))
                        }

                        head
                    }
                    .border(Color.gray)

                    FlowStack(alignment: .init(horizontal: .center, vertical: .label)) {
                        tail

                        ForEach(1..<5) { num in
                            Text(String(num))
                                .frame(minWidth: 30, minHeight: 30)
                                .background(Circle().fill(Color.blue))
                        }

                        head
                    }
                    .border(Color.gray)

                    FlowStack(alignment: .leading) {
                        tail
                        list
                        head
                    }
                    .border(Color.gray)

                    FlowStack(alignment: .center) {
                        tail
                        list
                        head
                    }
                    .border(Color.gray)

                    FlowStack(alignment: .trailing) {
                        tail
                        list
                        head
                    }
                    .border(Color.gray)

                    FlowStack(
                        alignment: .center,
                        columnSpacing: 0,
                        rowSpacing: 0
                    ) {
                        tail
                        list
                        head
                    }
                    .border(Color.gray)
                }
            }
        }
    }

    struct Preview2: View {
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fill")
                        .font(.title)

                    FlowStack(alignment: .leading, options: .fill) {
                        TagView(label: "Lorem ipsum dolor", color: .green)
                        TagView(label: "Lorem ipsum dolor sit amet consectetur", color: .blue)
                        TagView(label: "Lorem ipsum", color: .red, padding: 4)
                        TagView(label: "Lorem ipsum dolor sit amet consectetur", color: .yellow)
                        TagView(label: "Lorem ipsum", color: .orange)
                        TagView(label: "Lorem ipsum dolor sit amet consectetur", color: .teal)
                        TagView(label: "Lorem ipsum dolor", color: .purple)
                    }

                    Divider()

                    FlowStack(alignment: .topTrailing, options: .fill) {
                        TagView(label: "Lorem ipsum dolor", color: .green)
                        TagView(label: "Lorem ipsum dolor sit amet consectetur", color: .blue)
                        TagView(label: "Lorem ipsum", color: .red, padding: 4)
                    }

                    Divider()

                    FlowStack(alignment: .bottomTrailing, options: .fill) {
                        TagView(label: "Lorem ipsum dolor", color: .green)
                        TagView(label: "Lorem ipsum dolor sit amet consectetur", color: .blue)
                        TagView(label: "Lorem ipsum", color: .red, padding: 4)
                    }

                    Divider()

                    Text("Min Rows")
                        .font(.title)

                    FlowStack(alignment: .leading, minimumNumberOfRows: 2) {
                        TagView(label: "Lorem XYZ", color: .green)
                        TagView(label: "Lorem", color: .blue)
                        TagView(label: "Lorem ", color: .red, padding: 4)
                        TagView(label: "Lorem", color: .yellow)
                        TagView(label: "Lorem", color: .orange)
                        TagView(label: "Lorem", color: .teal)
                    }

                    Divider()

                    FlowStack(alignment: .leading, options: .fill, minimumNumberOfRows: 2) {
                        TagView(label: "Lorem", color: .green)
                        TagView(label: "Lorem", color: .blue)
                        TagView(label: "Lorem", color: .red, padding: 4)
                        TagView(label: "Lorem", color: .yellow)
                        TagView(label: "Lorem", color: .orange)
                        TagView(label: "Lorem", color: .teal)
                    }

                    Divider()

                    Text("Scrollable")
                        .font(.title)

                    ScrollView(.horizontal, showsIndicators: false) {
                        FlowStack(alignment: .leading) {
                            TagView(label: "Lorem ipsum dolor", color: .green)
                            TagView(label: "Lorem ipsum dolor sit amet consectetur", color: .blue)
                            TagView(label: "Lorem ipsum", color: .red, padding: 4)
                            TagView(label: "Lorem ipsum dolor sit amet consectetur", color: .yellow)
                            TagView(label: "Lorem ipsum", color: .orange)
                            TagView(label: "Lorem ipsum dolor sit amet consectetur", color: .teal)
                            TagView(label: "Lorem ipsum dolor", color: .purple)
                        }
                    }

                    Divider()

                    ScrollView(.horizontal, showsIndicators: false) {
                        FlowStack(alignment: .leading, minimumNumberOfRows: 2) {
                            TagView(label: "Lorem ipsum dolor", color: .green)
                            TagView(label: "Lorem ipsum dolor sit amet consectetur", color: .blue)
                            TagView(label: "Lorem ipsum", color: .red, padding: 4)
                            TagView(label: "Lorem ipsum dolor sit amet consectetur", color: .yellow)
                            TagView(label: "Lorem ipsum", color: .orange)
                            TagView(label: "Lorem ipsum dolor sit amet consectetur", color: .teal)
                            TagView(label: "Lorem ipsum dolor", color: .purple)
                        }
                    }
                }
            }
        }

        struct TagView: View {
            var label: String
            var color: Color
            var padding: CGFloat = 0

            var body: some View {
                HStack(spacing: 4) {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)

                    Text(label)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .padding(padding)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(color.opacity(0.1))

                        RoundedRectangle(cornerRadius: 24)
                            .inset(by: 0.5)
                            .strokeBorder(color, lineWidth: 1)
                    }
                }
            }
        }
    }

    struct Preview3: View {
        @State var width: CGFloat = 260

        var body: some View {
            VStack {
                Text(width.rounded().description)
                #if os(iOS) || os(macOS)
                Slider(value: $width, in: 10...375)
                #endif

                FlowStack {
                    ScrollView {
                        VStack(alignment: .center, spacing: 24) {
                            FlowStack(
                                alignment: Alignment(
                                    horizontal: .center,
                                    vertical: .firstTextBaseline
                                )
                            ) {
                                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")

                                Divider()

                                Text("Hello World").font(.title) + Text("Hello World")
                            }
                        }
                        .frame(width: width)
                        .border(Color.gray)
                    }
                }
            }
            .padding()
        }
    }
}
