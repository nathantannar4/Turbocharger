//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@frozen
public struct MarqueeHStack<Content: View>: View {

    var spacing: CGFloat
    var content: Content

    @State var startAt = Date.now.addingTimeInterval(2)
    @Environment(\.displayScale) var displayScale

    public init(
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing ?? 4
        self.content = content()
    }

    public var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            content
                .lineLimit(1)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityHidden(false)
        .opacity(0)
        .overlay {
            let interval: TimeInterval = 1 / 120
            TimelineView(
                .periodic(from: startAt, by: interval)
            ) { ctx in

                let period = ctx.date.timeIntervalSince(startAt)
                let timestamp = max(0, period / 15) // Speed factor

                VariadicViewAdapter {
                    content
                } content: { source in
                    Canvas(rendersAsynchronously: true) { ctx, size in
                        let symbols = source.children.compactMap {
                            ctx.resolveSymbol(id: $0.id)
                        }
                        let requiredWidth = symbols.map(\.size.width).reduce(0, +) + spacing * CGFloat(source.children.count - 1)
                        let x = (requiredWidth * timestamp).truncatingRemainder(dividingBy: requiredWidth)
                        var origin = CGPoint(
                            x: requiredWidth > size.width ? -x : 0,
                            y: size.height / 2
                        )

                        func round(value: CGFloat) -> CGFloat {
                            (value * displayScale).rounded() / displayScale
                        }

                        func draw(symbol: GraphicsContext.ResolvedSymbol) {
                            let rect = CGRect(
                                x: round(value: origin.x),
                                y: round(value: origin.y - symbol.size.height / 2),
                                width: round(value: symbol.size.width),
                                height: round(value: symbol.size.height)
                            )
                            ctx.draw(symbol, in: rect)
                            origin.x += rect.size.width + spacing
                        }

                        for symbol in symbols {
                            draw(symbol: symbol)
                        }
                        for symbol in symbols {
                            if origin.x < requiredWidth {
                                draw(symbol: symbol)
                            } else {
                                break
                            }
                        }

                    } symbols: {
                        source
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
        }
        .onTapGesture {
            startAt = .now.addingTimeInterval(2)
        }
    }
}
