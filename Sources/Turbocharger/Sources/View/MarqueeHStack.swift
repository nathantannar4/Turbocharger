//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@frozen
public struct MarqueeHStack<Selection: Hashable, Content: View>: View {

    public var spacing: CGFloat
    public var speed: Double
    public var isScrollEnabled: Bool
    public var content: Content

    private var selection: Binding<Selection>?
    @State var startAt: Date

    public init(
        spacing: CGFloat? = nil,
        speed: Double = 1,
        delay: TimeInterval = 2,
        isScrollEnabled: Bool = true,
        @ViewBuilder content: () -> Content
    ) where Selection == Never {
        self.selection = nil
        self.spacing = spacing ?? 4
        self.speed = speed
        self.isScrollEnabled = isScrollEnabled
        self.content = content()
        self._startAt = State(wrappedValue: Date.now.addingTimeInterval(delay))
    }

    public init(
        selection: Binding<Selection>,
        spacing: CGFloat? = nil,
        speed: Double = 1,
        delay: TimeInterval = 2,
        isScrollEnabled: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.selection = selection
        self.spacing = spacing ?? 4
        self.speed = speed
        self.isScrollEnabled = isScrollEnabled
        self.content = content()
        self._startAt = State(wrappedValue: Date.now.addingTimeInterval(delay))
    }

    public var body: some View {
        ZStack {
            content
        }
        .frame(maxWidth: .infinity)
        .hidden()
        .overlay {
            VariadicViewAdapter {
                content
            } content: { source in
                TimelineView(
                    .animation(minimumInterval: nil, paused: !isScrollEnabled)
                ) { ctx in
                    MarqueeHStackBody(
                        selection: selection,
                        views: source.children,
                        keyframe: max(0, ctx.date.timeIntervalSince(startAt)),
                        speed: speed,
                        spacing: spacing
                    )
                }
            }
            .accessibilityRepresentation {
                HStack(alignment: .center, spacing: spacing) {
                    content
                        .lineLimit(1)
                }
            }
        }
    }
}

private class MarqueeHStackNodesBox {
    var nodes: [MarqueeHStackNodeProxy] = []
}

private struct MarqueeHStackNodeProxy {
    var id: AnyHashable
    var frame: CGRect
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct MarqueeHStackBody<Selection: Hashable>: View {

    var selection: Binding<Selection>?
    var views: AnyVariadicView
    var keyframe: TimeInterval
    var speed: Double
    var spacing: CGFloat

    @State var box: MarqueeHStackNodesBox?

    init(
        selection: Binding<Selection>? = nil,
        views: AnyVariadicView,
        keyframe: TimeInterval,
        speed: Double,
        spacing: CGFloat
    ) {
        self.selection = selection
        self.views = views
        self.keyframe = keyframe
        self.speed = speed
        self.spacing = spacing
        self._box =  State(wrappedValue: selection != nil ? MarqueeHStackNodesBox() : nil)
    }

    var body: some View {
        Canvas(rendersAsynchronously: true) { ctx, size in
            draw(ctx: ctx, size: size)
        } symbols: {
            views
        }
        .overlay {
            if let selection {
                Rectangle()
                    .hidden()
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                guard let selected = box?.nodes.first(where: { $0.frame.contains(value.location) }),
                                      let id = selected.id as? Selection
                                else {
                                    return
                                }
                                selection.wrappedValue = id
                            }
                    )
            }
        }
    }

    private struct ResolvedSymbol {
        var id: AnyHashable
        var symbol: GraphicsContext.ResolvedSymbol
    }

    private struct Node {
        var symbol: GraphicsContext.ResolvedSymbol
        var frame: CGRect

        init(symbol: GraphicsContext.ResolvedSymbol, origin: CGPoint) {
            self.symbol = symbol
            self.frame = CGRect(
                x: origin.x,
                y: origin.y - symbol.size.height / 2,
                width: symbol.size.width,
                height: symbol.size.height
            )
        }
    }

    private func draw(ctx: GraphicsContext, size: CGSize) {
        let resolvedSymbols: [ResolvedSymbol] = views.compactMap {
            guard let symbol = ctx.resolveSymbol(id: $0.id) else {
                return nil
            }
            if let id = $0.id(as: Selection.self) {
                return ResolvedSymbol(id: id, symbol: symbol)
            }
            return ResolvedSymbol(id: $0.id, symbol: symbol)
        }
        guard !resolvedSymbols.isEmpty else {
            return
        }

        let requiredWidth = resolvedSymbols.map(\.symbol.size.width).reduce(0, +) + spacing * CGFloat(views.count - 1)
        let timestamp = keyframe / 20 * speed
        let dx = (requiredWidth * timestamp).truncatingRemainder(dividingBy: requiredWidth).rounded()
        var origin = CGPoint(
            x: 0,
            y: (size.height / 2).rounded()
        )

        if requiredWidth > size.width {
            if speed > 0 {
                origin.x -= dx
            } else if speed < 0 {
                origin.x -= dx
            }
        }

        var proxies = [MarqueeHStackNodeProxy]()

        for resolvedSymbol in resolvedSymbols {
            let node = Node(symbol: resolvedSymbol.symbol, origin: origin)
            ctx.draw(node.symbol, in: node.frame)
            origin.x += (node.frame.size.width + spacing)
            proxies.append(MarqueeHStackNodeProxy(id: resolvedSymbol.id, frame: node.frame))
        }

        if speed < 0 {
            origin.x = -dx - (requiredWidth + spacing)
        }

        for resolvedSymbol in resolvedSymbols {
            let node = Node(symbol: resolvedSymbol.symbol, origin: origin)
            ctx.draw(node.symbol, in: node.frame)
            origin.x += (node.frame.size.width + spacing)
            proxies.append(MarqueeHStackNodeProxy(id: resolvedSymbol.id, frame: node.frame))
        }

        box?.nodes = proxies
    }
}
