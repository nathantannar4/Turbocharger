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

    public var axis: Axis
    public var estimatedDimension: CGFloat
    public var itemSpacing: CGFloat
    public var sectionSpacing: CGFloat
    public var contentInsets: EdgeInsets
    public var pinnedViews: Set<CollectionViewSupplementaryView.ID>

    @inlinable
    public init(
        axis: Axis = .vertical,
        estimatedDimension: CGFloat? = nil,
        itemSpacing: CGFloat = 0,
        sectionSpacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = []
    ) {
        self.axis = axis
        switch axis {
        case .vertical:
            self.estimatedDimension = estimatedDimension ?? 60
        case .horizontal:
            self.estimatedDimension = estimatedDimension ?? 400
        }
        self.itemSpacing = itemSpacing
        self.sectionSpacing = sectionSpacing
        self.contentInsets = contentInsets
        self.pinnedViews = pinnedViews
    }

    #if os(iOS)
    public func makeUICollectionViewLayout(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: axis == .vertical ? .fractionalWidth(1.0) : .estimated(estimatedDimension),
            heightDimension: axis == .vertical ? .estimated(estimatedDimension) : .fractionalHeight(1.0)
        )

        let item = NSCollectionLayoutItem(
            layoutSize: itemSize
        )
        let group: NSCollectionLayoutGroup = {
            switch axis {
            case .vertical:
                NSCollectionLayoutGroup.vertical(
                    layoutSize: itemSize,
                    subitems: [item]
                )
            case .horizontal:
                NSCollectionLayoutGroup.horizontal(
                    layoutSize: itemSize,
                    subitems: [item]
                )
            }
        }()

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = itemSpacing
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
                }(),
                absoluteOffset: supplementaryView.offset
            )
            item.contentInsets = NSDirectionalEdgeInsets(supplementaryView.contentInset)
            item.zIndex = supplementaryView.zIndex
            item.pinToVisibleBounds = pinnedViews.contains(supplementaryView.id)
            section.boundarySupplementaryItems.append(item)
        }

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = sectionSpacing
        switch axis {
        case .vertical:
            configuration.scrollDirection = .vertical
        case .horizontal:
            configuration.scrollDirection = .horizontal
        }
        let layout = UICollectionViewCompositionalLayout(
            section: section,
            configuration: configuration
        )
        return layout
    }

    public func makeUICollectionView(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionView {

        let layout = makeUICollectionViewLayout(context: context, options: options)
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

    public static var compositional: CollectionViewCompositionalLayout { .compositional() }

    public static func compositional(
        axis: Axis = .vertical,
        estimatedDimension: CGFloat? = nil,
        spacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = []
    ) -> CollectionViewCompositionalLayout {
        .compositional(
            axis: axis,
            estimatedDimension: estimatedDimension,
            itemSpacing: spacing,
            contentInsets: contentInsets,
            pinnedViews: pinnedViews
        )
    }

    public static func compositional(
        axis: Axis = .vertical,
        estimatedDimension: CGFloat? = nil,
        itemSpacing: CGFloat = 0,
        sectionSpacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = []
    ) -> CollectionViewCompositionalLayout {
        CollectionViewCompositionalLayout(
            axis: axis,
            estimatedDimension: estimatedDimension,
            itemSpacing: itemSpacing,
            sectionSpacing: sectionSpacing,
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
        CollectionView(
            .compositional(spacing: 12, pinnedViews: [.header]),
            sections: [[1, 2, 3]],
            id: \.self
        ) { id in
            CellView(axis: .vertical, text: "Cell \(id)")
        } header: { _ in
            HeaderFooter(axis: .vertical, isHeader: true)
        } footer: { _ in
            HeaderFooter(axis: .vertical, isHeader: false)
        }

        CollectionView(
            .compositional(
                itemSpacing: 12,
                sectionSpacing: 4,
                contentInsets: .init(top: 8, leading: 8, bottom: 8, trailing: 8)
            ),
            sections: [[1, 2, 3], [4, 5, 6]],
            id: \.self
        ) { id in
            CellView(axis: .vertical, text: "Cell \(id)")
        } header: { _ in
            HeaderFooter(axis: .vertical, isHeader: true)
        } footer: { _ in
            HeaderFooter(axis: .vertical, isHeader: false)
        }

        CollectionView(
            .compositional(axis: .horizontal, spacing: 12, pinnedViews: [.header]),
            sections: [[1, 2, 3], [4, 5, 6]],
            id: \.self
        ) { id in
            CellView(axis: .horizontal, text: "Cell \(id)")
        } header: { _ in
            HeaderFooter(axis: .horizontal, isHeader: true)
        } footer: { _ in
            HeaderFooter(axis: .horizontal, isHeader: false)
        }

        ScrollView {
            CollectionView(
                .compositional(axis: .horizontal, spacing: 12, pinnedViews: [.header]),
                sections: [[1, 2, 3], [4, 5, 6]],
                id: \.self
            ) { id in
                CellView(axis: .horizontal, text: "Cell \(id)")
            } header: { _ in
                HeaderFooter(axis: .horizontal, isHeader: true)
            } footer: { _ in
                HeaderFooter(axis: .horizontal, isHeader: false)
            }
        }

        CollectionView(
            .compositional(
                spacing: 12,
                pinnedViews: [.header]
            ),
            sections: [(0..<3).map { IdentifiableBox($0, id: \.self) }],
            supplementaryViews: [
                .header,
                .custom(
                    "banner",
                    alignment: .topLeading,
                    offset: CGPoint(x: 0, y: -24)
                ),
                .custom(
                    "card",
                    alignment: .bottom,
                    offset: CGPoint(x: 0, y: 24)
                )
            ]
        ) { id in
            CellView(axis: .vertical, text: "Cell \(id.value)")
        } header: { _ in
            HeaderFooter(axis: .vertical, isHeader: true)
        } footer: { _ in
            HeaderFooter(axis: .vertical, isHeader: false)
        } supplementaryView: { id, index in
            Color.purple
                .overlay { Text("\(id)") }
                .frame(height: 100)
                .border(Color.pink, width: 5)
        }
    }

    struct CellView: View {
        var axis: Axis
        var text: String

        var body: some View {
            Text(text)
                .frame(maxWidth: axis == .vertical ? .infinity : nil, maxHeight: axis == .horizontal ? .infinity : nil)
                .padding()
                .background(Color.red)
        }
    }

    struct HeaderFooter: View {
        var axis: Axis
        var isHeader: Bool

        var body: some View {
            Text(isHeader ? "Header" : "Footer")
                .frame(maxWidth: axis == .vertical ? .infinity : nil, minHeight: 24, maxHeight: axis == .horizontal ? .infinity : nil)
                .background(Color.blue)
        }
    }
}
#endif
