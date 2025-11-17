//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public struct RedactedTextRenderer<S: Shape>: TextRenderer {

    public var isRedacted: Bool?
    public var color: Color?
    public var shape: S
    public var edgeInsets: EdgeInsets

    public init(
        isRedacted: Bool? = nil,
        color: Color? = nil,
        shape: S,
        edgeInsets: EdgeInsets
    ) {
        self.isRedacted = isRedacted
        self.color = color
        self.shape = shape
        self.edgeInsets = edgeInsets
    }

    public init(
        isRedacted: Bool? = nil,
        color: Color? = nil,
    ) where S == RoundedRectangle {
        self.init(
            isRedacted: isRedacted,
            color: color,
            shape: RoundedRectangle(cornerRadius: 4),
            edgeInsets: EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        )
    }

    public func draw(
        layout: Text.Layout,
        in ctx: inout GraphicsContext
    ) {
        let isRedacted = isRedacted ?? !ctx.environment.redactionReasons.isEmpty
        #if os(macOS)
        let edgeInsets = edgeInsets.toNSEdgeInsets(
            layoutDirection: ctx.environment.layoutDirection
        )
        #else
        let edgeInsets = edgeInsets.toUIEdgeInsets(
            layoutDirection: ctx.environment.layoutDirection
        )
        #endif
        for line in layout {
            if isRedacted {
                let bounds = line.typographicBounds.rect
                    .integral.inset(by: edgeInsets)
                let path = shape.path(in: bounds)
                if let color {
                    ctx.fill(path, with: .color(color))
                } else {
                    ctx.fill(path, with: .style(.foreground.opacity(0.16)))
                }
            } else {
                ctx.draw(line)
            }
        }
    }
}

#if os(macOS)

extension CGRect {
    func inset(by insets: NSEdgeInsets) -> CGRect {
        CGRect(
            x: origin.x + insets.left,
            y: origin.y + insets.top,
            width: size.width - (insets.left + insets.right),
            height: size.height - (insets.top + insets.bottom)
        )
    }
}

#endif

// MARK: - Previews

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
struct RedactedTextRenderer_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let text = Text("Line 1\nLine 123")
            text
                .redacted(reason: .placeholder)
                .foregroundStyle(.red)

            ZStack {
                text
                    .textRenderer(RedactedTextRenderer(isRedacted: true))

                text
            }
            .foregroundStyle(.red)

            Divider()

            VStack(spacing: 0) {
                ForEach(2) {
                    HStack(spacing: 0) {
                        ForEach(2) {
                            text
                        }
                    }
                }
            }
            .textRenderer(RedactedTextRenderer(isRedacted: true))

            Divider()

            VStack(spacing: 0) {
                ForEach(2) {
                    HStack(spacing: 0) {
                        ForEach(2) {
                            text
                        }
                    }
                }
            }
            .redacted(reason: .placeholder)

            Divider()

            VStack(spacing: 0) {
                ForEach(2) {
                    HStack(spacing: 0) {
                        ForEach(2) {
                            text
                        }
                    }
                }
            }
            .redacted(reason: .placeholder)
            .textRenderer(RedactedTextRenderer(isRedacted: true))
        }

        VStack {
            StateAdapter(initialValue: true) { $isRedacted in
                Text(isRedacted ? "*****" : "Line 1\nLine 123")
                    .textRenderer(RedactedTextRenderer(isRedacted: isRedacted))
                    .unredacted()
                    .shimmer(isActive: isRedacted)
                    .onTapGesture {
                        withAnimation {
                            isRedacted.toggle()
                        }
                    }
            }
        }
    }
}
