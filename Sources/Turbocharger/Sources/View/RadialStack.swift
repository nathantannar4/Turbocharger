//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A view that arranges its subviews along a radial circumference.
@frozen
public struct RadialStack<Content: View>: VersionedView {

    public var radius: CGFloat?
    public var content: Content

    public init(radius: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var v4Body: some View {
        RadialStackLayout(radius: radius) {
            content
        }
    }

    public var v1Body: some View {
        VariadicViewAdapter {
            content
        } content: { source in
            ZStack(alignment: .topLeading) {
                GeometryReader { proxy in
                    let radius = (radius ?? min(proxy.size.width, proxy.size.height) / 2) / 1.5
                    let angle = 2.0 / CGFloat(source.children.count) * .pi
                    ForEachSubview(source) { index, subview in
                        subview
                            .position(
                                x: proxy.size.width / 2 + cos(angle * CGFloat(index) - .pi / 2) * radius,
                                y: proxy.size.height / 2 + sin(angle * CGFloat(index) - .pi / 2) * radius
                            )
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }
}

/// A layout that arranges subviews along a radial circumference.
@frozen
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct RadialStackLayout: Layout {

    public var radius: CGFloat?

    public init(radius: CGFloat?) {
        self.radius = radius
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let size = proposal.replacingUnspecifiedDimensions()
        let length = min(size.width, size.height)
        return CGSize(width: length, height: length)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let radius = radius ?? min(bounds.size.width, bounds.size.height) / 2
        let angle = 2.0 / CGFloat(subviews.count) * .pi

        for (index, subview) in subviews.enumerated() {
            let sizeThatFits = subview.sizeThatFits(.unspecified)
            var point = CGPoint(x: bounds.midX, y: bounds.midY)

            point.x += cos(angle * CGFloat(index) - .pi / 2) * (radius - sizeThatFits.width / 2)
            point.y += sin(angle * CGFloat(index) - .pi / 2) * (radius - sizeThatFits.height / 2)

            subview.place(at: point, anchor: .center, proposal: .unspecified)
        }
    }
}

// MARK: - Previews

struct CircleLayout_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RadialStack {
                Color.blue
                    .frame(width: 80, height: 80)

                Color.red
                    .frame(width: 80, height: 80)
            }
            .background(Color.black)

            RadialStack {
                Color.blue
                    .frame(width: 80, height: 80)

                Color.yellow
                    .frame(width: 80, height: 80)

                Color.red
                    .frame(width: 80, height: 80)
            }
            .background(Color.black)

            RadialStack {
                Color.blue
                    .frame(width: 80, height: 80)

                Color.yellow
                    .frame(width: 80, height: 80)

                Color.red
                    .frame(width: 80, height: 80)

                Color.green
                    .frame(width: 80, height: 80)

                Color.purple
                    .frame(width: 80, height: 80)

                Color.pink
                    .frame(width: 80, height: 80)
            }
            .background(Color.black)
        }
    }
}
