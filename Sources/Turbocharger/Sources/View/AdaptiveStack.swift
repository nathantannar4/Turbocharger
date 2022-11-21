//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A view that arranges its subviews in a horizontal line when such a layout
/// would fit the available space. If there is not enough space, it arranges it's subviews
/// in a vertical line.
@frozen
public struct AdaptiveStack<Content: View>: VersionedView {

    public var alignment: Alignment
    public var spacing: CGFloat?
    public var content: Content

    @Environment(\.self) var environment

    var axis: Axis {
        #if os(iOS)
        if environment.horizontalSizeClass != .regular {
            if #available(iOS 15.0, *) {
                if environment.dynamicTypeSize.isAccessibilitySize {
                    return .vertical
                }
            } else if UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
                return .vertical
            }
        }
        #endif
        return .horizontal
    }

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
        LayoutAdapter {
            switch axis {
            case .vertical:
                _VStackLayout(alignment: alignment.horizontal, spacing: spacing)
            case .horizontal:
                LayoutThatFits(
                    in: .horizontal,
                    _HStackLayout(alignment: alignment.vertical, spacing: spacing),
                    _VStackLayout(alignment: alignment.horizontal, spacing: spacing)
                )
            }
        } content: {
            content
        }
    }

    public var v1Body: some View {
        HVStack(axis: axis, alignment: alignment, spacing: spacing) {
            content
        }
    }
}

// MARK: - Previews

struct AdaptiveStack_Previews: PreviewProvider {
    struct Preview: View {
        @State private var isRestricted = false

        var content: some View {
            Group {
                Text("Layout")
                Text("That")
                Text("Fits")
            }
            .lineLimit(1)
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
        }

        var body: some View {
            VStack {
                Toggle(isOn: $isRestricted) {
                    EmptyView()
                }

                VStack {
                    AdaptiveStack {
                        content
                    }

                    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                        AdaptiveStack {
                            content
                        }
                        .dynamicTypeSize(.accessibility1)
                    }
                }
                .frame(width: isRestricted ? 100 : nil)
                .background(Color.gray)
                .animation(.default, value: isRestricted)

                Spacer()
            }
            .padding()
        }
    }

    static var previews: some View {
        Preview()
    }
}
