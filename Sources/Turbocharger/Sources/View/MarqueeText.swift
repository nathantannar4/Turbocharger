//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct MarqueeText: View {

    public var text: Text
    public var spacing: CGFloat
    public var speed: Double

    @State private var startAt: Date = .now

    @_disfavoredOverload
    public init<S: StringProtocol>(
        _ text: S,
        spacing: CGFloat = 8,
        speed: Double = 1
    ) {
        self.init(
            Text(text),
            spacing: spacing,
            speed: speed
        )
    }

    public init(
        _ text: LocalizedStringKey,
        spacing: CGFloat = 8,
        speed: Double = 1
    ) {
        self.init(
            Text(text),
            spacing: spacing,
            speed: speed
        )
    }

    public init(
        _ text: Text,
        spacing: CGFloat = 8,
        speed: Double = 1
    ) {
        self.text = text
        self.spacing = spacing
        self.speed = speed
    }

    public var body: some View {
        text
            .hidden()
            .overlay {
                TimelineView(
                    .periodic(from: startAt, by: 1 / 60)
                ) { ctx in
                    let keyframe = max(0, ctx.date.timeIntervalSince(startAt))
                    MarqueeTextBody(
                        text: text,
                        spacing: spacing,
                        speed: speed,
                        keyframe: keyframe
                    )
                }
            }
            .accessibilityRepresentation {
                text
            }
            .lineLimit(1)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct MarqueeTextBody: View {
    var text: Text
    var spacing: CGFloat
    var speed: Double
    var keyframe: Double

    var body: some View {
        Canvas(rendersAsynchronously: false) { ctx, size in
            let frame = CGRect(
                x: spacing,
                y: 0,
                width: size.width - 2 * spacing,
                height: size.height
            )
            let resolvedText = ctx.resolve(text)
            let sizeThatFits = resolvedText.measure(
                in: CGSize(width: .infinity, height: frame.size.height)
            )
            var rect = CGRect(
                origin: CGPoint(
                    x: frame.origin.x,
                    y: (frame.size.height - sizeThatFits.height) / 2
                ),
                size: sizeThatFits
            )
            if sizeThatFits.width <= frame.size.width {
                ctx.draw(resolvedText, in: rect)
            } else {
                let timestamp = keyframe * 40 * speed
                let delayOffset: CGFloat = 100
                var dx = timestamp
                    .truncatingRemainder(
                        dividingBy: max(frame.size.width, sizeThatFits.width + spacing) + min(delayOffset, sizeThatFits.width)
                    ) - delayOffset
                dx = (dx * ctx.environment.displayScale).rounded() / ctx.environment.displayScale

                rect.origin.x -= dx
                rect.origin.x = min(frame.origin.x, rect.origin.x)
                ctx.draw(resolvedText, in: rect)

                rect.origin.x = frame.origin.x + sizeThatFits.width + spacing - dx
                rect.origin.x = max(frame.origin.x, rect.origin.x)
                ctx.draw(text, in: rect)
            }
        }
        .mask {
            GeometryReader { proxy in
                let inset = spacing / proxy.size.width
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: inset),
                        .init(color: .black, location: 1 - inset),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        .padding(.horizontal, -spacing)
    }
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct MarqueeText_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var width: CGFloat = 185
        @State var id = 0

        var body: some View {
            VStack(spacing: 12) {
                Text(width.description)
                #if os(iOS) || os(macOS)
                Slider(value: $width, in: 100...300)
                #endif
                Button("Reset") { id += 1 }

                MarqueeText(
                    "One Two Three Four Five"
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                MarqueeText(
                    "One Two Three Four Five"
                )
                .id(id)
                .frame(width: width / 4, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)

                MarqueeText(
                    "One Two Three Four Five"
                )
                .id(id)
                .frame(width: width, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)

                MarqueeText(
                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
                )
                .id(id)

                MarqueeText(
                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
                )
                .id(id)
            }
            .padding(.horizontal, 24)
        }
    }
}
