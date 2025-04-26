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
    public var pinnedViews: Set<CollectionViewSupplementaryView.ID>

    @inlinable
    public init(
        spacing: CGFloat,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = []
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
            heightDimension: .estimated(44)
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
        if #available(iOS 16.0, *) {
            section.supplementaryContentInsetsReference = .none
        } else {
            section.supplementariesFollowContentInsets = false
        }

        for supplementaryView in options.supplementaryViews {
            let item = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: itemSize,
                elementKind: supplementaryView.kind,
                alignment: {
                    switch supplementaryView.alignment {
                    case .top:
                        return .top
                    case .topLeading:
                        return .topLeading
                    case .topTrailing:
                        return .topLeading
                    case .bottom:
                        return .bottom
                    case .bottomLeading:
                        return .bottomLeading
                    case .bottomTrailing:
                        return .bottomTrailing
                    case .leading:
                        return .leading
                    case .trailing:
                        return .trailing
                    default:
                        return .none
                    }
                }()
            )
            item.contentInsets = NSDirectionalEdgeInsets(supplementaryView.contentInset)
            item.zIndex = supplementaryView.id == .header || supplementaryView.id == .footer ? 1 : 0
            item.pinToVisibleBounds = pinnedViews.contains(supplementaryView.id)
            section.boundarySupplementaryItems.append(item)
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

    public static func compositional(
        spacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = []
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
                .compositional(spacing: 12, pinnedViews: [.header]),
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
                .compositional(spacing: 12, contentInsets: .init(top: 8, leading: 8, bottom: 8, trailing: 8)),
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
