//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A view that arranges its subviews in a vertical or horizontal line.
@frozen
public struct HVStack<Content: View>: VersionedView {

    public var axis: Axis
    public var alignment: Alignment
    public var spacing: CGFloat?
    public var content: Content

    public init(
        axis: Axis,
        alignment: Alignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.axis = axis
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var v4Body: some View {
        LayoutAdapter {
            switch axis {
            case .vertical:
                _VStackLayout(alignment: alignment.horizontal, spacing: spacing)
            case .horizontal:
                _HStackLayout(alignment: alignment.vertical, spacing: spacing)
            }
        } content: {
            content
        }
    }

    public var v1Body: some View {
        switch axis {
        case .vertical:
            VStack(alignment: alignment.horizontal, spacing: spacing) {
                content
            }
            .transition(.identity)
        case .horizontal:
            HStack(alignment: alignment.vertical, spacing: spacing) {
                content
            }
            .transition(.identity)
        }
    }
}

// MARK: - Previews

struct HVStack_Previews: PreviewProvider {
    struct Preview: View {
        @State var isVertical: Bool = true

        var body: some View {
            VStack {
                Toggle("isVertical", isOn: $isVertical)

                HVStack(axis: isVertical ? .vertical : .horizontal, spacing: 0) {
                    Color.red.frame(width: 100, height: 30)

                    Color.blue.frame(width: 100, height: 30)
                }
            }
            .animation(.default, value: isVertical)
        }
    }

    static var previews: some View {
        Preview()
    }
}
