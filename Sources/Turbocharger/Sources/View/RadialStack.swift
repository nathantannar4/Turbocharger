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
        } content: { children in
            ZStack(alignment: .topLeading) {
                GeometryReader { proxy in
                    let radius = (radius ?? min(proxy.size.width, proxy.size.height) / 2) / 1.5
                    let angle = 2.0 / CGFloat(children.count) * .pi
                    ForEachSubview(children) { index, subview in
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
        if let radius {
            let length = radius * 2
            return CGSize(width: length, height: length)
        }
        var size = CGSize.zero
        for subview in subviews {
            let sizeThatFits = subview.sizeThatFits(.unspecified)
            size.width = max(size.width, sizeThatFits.width)
            size.height = max(size.height, sizeThatFits.height)
        }
        let length = round(.pi * min(size.width, size.height))
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
            RadialStack(radius: 40) {
                Group {
                    Circle()
                        .fill(Color.blue)

                    Circle()
                        .fill(Color.red)

                    Circle()
                        .fill(Color.yellow)
                }
                .frame(width: 40, height: 40)
            }
            .border(Color.black)

            RadialStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 60, height: 60)

                Circle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)

                Circle()
                    .fill(Color.yellow)
                    .frame(width: 40, height: 40)
            }
            .border(Color.black)

            RadialStack {
                Group {
                    Circle()
                        .fill(Color.blue)

                    Circle()
                        .fill(Color.purple)

                    Circle()
                        .fill(Color.red)

                    Circle()
                        .fill(Color.orange)

                    Circle()
                        .fill(Color.yellow)

                    Circle()
                        .fill(Color.green)
                        .frame(width: 75, height: 75)
                }
                .frame(width: 50, height: 50)
            }
            .border(Color.black)
        }
    }
}
