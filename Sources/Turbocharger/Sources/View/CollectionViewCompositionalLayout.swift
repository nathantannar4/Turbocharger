//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A ``CollectionViewLayout``
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct CollectionViewCompositionalLayout: CollectionViewLayout {

    public var spacing: CGFloat
    public var contentInsets: EdgeInsets
    public var pinnedViews: CollectionViewLayoutOptions

    @inlinable
    public init(
        spacing: CGFloat,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: CollectionViewLayoutOptions = []
    ) {
        self.spacing = spacing
        self.contentInsets = contentInsets
        self.pinnedViews = pinnedViews
    }

    #if os(iOS)
    public func makeUICollectionView(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionView {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(60)
        )
        let item = NSCollectionLayoutItem(
            layoutSize: itemSize
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: itemSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(contentInsets)
        section.supplementariesFollowContentInsets = false

        if options.contains(.header) {
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: itemSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .topLeading
            )
            header.pinToVisibleBounds = pinnedViews.contains(.header)
            section.boundarySupplementaryItems.append(header)
        }
        if options.contains(.footer) {
            let footer = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: itemSize,
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottomLeading
            )
            footer.pinToVisibleBounds = pinnedViews.contains(.footer)
            section.boundarySupplementaryItems.append(footer)
        }

        let layout = UICollectionViewCompositionalLayout(section: section)

        let uiCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        uiCollectionView.clipsToBounds = false
        uiCollectionView.keyboardDismissMode = .interactive
        uiCollectionView.backgroundColor = nil
        return uiCollectionView
    }

    public func updateUICollectionView(
        _ collectionView: UICollectionView,
        context: Context
    ) { }
    #endif
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionViewLayout where Self == CollectionViewCompositionalLayout {

    public static var list: CollectionViewCompositionalLayout { CollectionViewCompositionalLayout(spacing: 0) }

    public static func list(
        spacing: CGFloat,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: CollectionViewLayoutOptions = []
    ) -> CollectionViewCompositionalLayout {
        CollectionViewCompositionalLayout(
            spacing: spacing,
            contentInsets: contentInsets,
            pinnedViews: pinnedViews
        )
    }
}

// MARK: - Previews

#if os(iOS)
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CollectionViewLayout_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            CollectionView(
                .list(spacing: 12, pinnedViews: [.header]),
                sections: [[1, 2, 3]],
                id: \.self
            ) { id in
                CellView("Cell \(id)")
            } header: { _ in
                HeaderFooter()
            } footer: { _ in
                HeaderFooter()
            }

            CollectionView(
                .list(spacing: 12, contentInsets: .init(top: 8, leading: 8, bottom: 8, trailing: 8)),
                sections: [[1, 2, 3]],
                id: \.self
            ) { id in
                CellView("Cell \(id)")
            } header: { _ in
                HeaderFooter()
            } footer: { _ in
                HeaderFooter()
            }
        }
    }

    struct CellView: View {
        var text: String
        init(_ text: String) {
            self.text = text
        }

        var body: some View {
            Text(text)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
        }
    }

    struct HeaderFooter: View {
        var body: some View {
            Text("Header/Footer")
                .frame(maxWidth: .infinity)
                .background(Color.blue)
        }
    }
}
#endif
