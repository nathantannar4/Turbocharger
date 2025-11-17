//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

#if os(iOS)

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct CollectionViewVariadicView<
    Layout: CollectionViewLayout,
    Content: View
>: View where
    Layout.UICollectionViewCellType: UICollectionViewCell,
    Layout.UICollectionViewSupplementaryViewType: UICollectionViewCell
{

    var layout: Layout
    var content: Content

    public init(
        layout: Layout,
        @ViewBuilder content: () -> Content
    ) {
        self.layout = layout
        self.content = content()
    }

    public var body: some View {
        VariadicViewAdapter {
            content
        } content: { content in
            CollectionView(
                layout,
                views: content
            ) { subview in
                subview
            }
        }
    }
}

#endif

// MARK: - Previews

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CollectionViewVariadicView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            CollectionViewVariadicView(
                layout: .insetGrouped
            ) {
                Text("Hello, World")
                VStack {
                    Text("Hello, World")
                    Text("Hello, World")
                }
                HStack {
                    Circle()
                        .frame(width: 24, height: 24)

                    Text("Hello, World")
                }
                ForEach(0..<3, id: \.self) { value in
                    Text(value, format: .number)
                }
            }
            .ignoresSafeArea()
        }

        ZStack {
            CollectionViewVariadicView(
                layout: .plain
            ) {
                ForEach(0..<10_000, id: \.self) { value in
                    Text(value, format: .number)
                }
            }
            .ignoresSafeArea()
        }
    }
}

#endif
