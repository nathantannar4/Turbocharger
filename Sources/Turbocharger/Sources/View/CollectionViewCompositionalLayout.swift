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

    @frozen
    public struct CollectionViewSupplementaryViewVisibility: Equatable, Sendable {

        @usableFromInline
        enum Visibility: Equatable, Sendable {
            case visible
            case hidden
        }

        var sections: IndexSet
        var visibility: Visibility

        public static func hidden(
            in sections: IndexSet
        ) -> CollectionViewSupplementaryViewVisibility {
            CollectionViewSupplementaryViewVisibility(
                sections: sections,
                visibility: .hidden
            )
        }

        public static func visible(
            in sections: IndexSet
        ) -> CollectionViewSupplementaryViewVisibility {
            CollectionViewSupplementaryViewVisibility(
                sections: sections,
                visibility: .visible
            )
        }
    }

    public var axis: Axis
    public var showsIndicators: Bool
    public var estimatedDimension: CGFloat
    public var itemSpacing: CGFloat
    public var sectionSpacing: CGFloat
    public var contentInsets: EdgeInsets
    public var pinnedViews: Set<CollectionViewSupplementaryView.ID>
    public var supplementaryViewVisibility: [CollectionViewSupplementaryView.ID: CollectionViewSupplementaryViewVisibility]

    @inlinable
    public init(
        axis: Axis = .vertical,
        showsIndicators: Bool = true,
        estimatedDimension: CGFloat? = nil,
        itemSpacing: CGFloat = 0,
        sectionSpacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = [],
        supplementaryViewVisibility: [CollectionViewSupplementaryView.ID: CollectionViewSupplementaryViewVisibility] = [:]
    ) {
        self.axis = axis
        self.showsIndicators = showsIndicators
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
        self.supplementaryViewVisibility = supplementaryViewVisibility
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

        let layoutItem = NSCollectionLayoutItem(
            layoutSize: itemSize
        )
        let layoutGroup: NSCollectionLayoutGroup = {
            switch axis {
            case .vertical:
                NSCollectionLayoutGroup.vertical(
                    layoutSize: itemSize,
                    subitems: [layoutItem]
                )
            case .horizontal:
                NSCollectionLayoutGroup.horizontal(
                    layoutSize: itemSize,
                    subitems: [layoutItem]
                )
            }
        }()

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = sectionSpacing
        switch axis {
        case .vertical:
            configuration.scrollDirection = .vertical
        case .horizontal:
            configuration.scrollDirection = .horizontal
        }
        let layout = UICollectionViewCompositionalLayout(
            sectionProvider: { section, environment in
                let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
                layoutSection.interGroupSpacing = itemSpacing
                layoutSection.contentInsets = NSDirectionalEdgeInsets(contentInsets)
                if #available(iOS 16.0, *) {
                    layoutSection.supplementaryContentInsetsReference = .none
                } else {
                    layoutSection.supplementariesFollowContentInsets = false
                }
                for supplementaryView in options.supplementaryViews {
                    let isVisible = {
                        guard
                            let visibility = supplementaryViewVisibility[supplementaryView.id]
                        else {
                            return true
                        }
                        if visibility.sections.contains(section) {
                            return visibility.visibility == .visible
                        }
                        return visibility.visibility != .visible
                    }()
                    guard isVisible else { continue }
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
                    layoutSection.boundarySupplementaryItems.append(item)
                }
                return layoutSection
            },
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
    ) {
        collectionView.showsVerticalScrollIndicator = showsIndicators
        collectionView.showsHorizontalScrollIndicator = showsIndicators
    }
    #endif
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionViewCompositionalLayout {

    public func supplementaryViewVisibility(
        _ visibility: CollectionViewSupplementaryViewVisibility,
        for id: CollectionViewSupplementaryView.ID
    ) -> CollectionViewCompositionalLayout {
        var copy = self
        copy.supplementaryViewVisibility[id] = visibility
        return copy
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionViewLayout where Self == CollectionViewCompositionalLayout {

    public static var compositional: CollectionViewCompositionalLayout { .compositional() }

    public static func compositional(
        axis: Axis = .vertical,
        showsIndicators: Bool = true,
        estimatedDimension: CGFloat? = nil,
        spacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = []
    ) -> CollectionViewCompositionalLayout {
        .compositional(
            axis: axis,
            showsIndicators: showsIndicators,
            estimatedDimension: estimatedDimension,
            itemSpacing: spacing,
            contentInsets: contentInsets,
            pinnedViews: pinnedViews
        )
    }

    public static func compositional(
        axis: Axis = .vertical,
        showsIndicators: Bool = true,
        estimatedDimension: CGFloat? = nil,
        itemSpacing: CGFloat = 0,
        sectionSpacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = []
    ) -> CollectionViewCompositionalLayout {
        CollectionViewCompositionalLayout(
            axis: axis,
            showsIndicators: showsIndicators,
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
            .compositional(
                spacing: 12,
                pinnedViews: [.header]
            ),
            sections: [
                CollectionViewSection(items: [1, 2, 3], id: \.self, section: 0),
            ]
        ) { indexPath, section, id in
            CellView(axis: .vertical, text: "Cell \(id.value)")
        } header: { _, _ in
            HeaderFooter(axis: .vertical, isHeader: true)
        } footer: { _, _ in
            HeaderFooter(axis: .vertical, isHeader: false)
        }
        .ignoresSafeArea()

        CollectionView(
            .compositional(
                itemSpacing: 12,
                sectionSpacing: 4,
                contentInsets: .init(top: 8, leading: 8, bottom: 8, trailing: 8)
            ),
            sections: [
                CollectionViewSection(items: [1, 2, 3], id: \.self, section: 0),
                CollectionViewSection(items: [4, 5, 6], id: \.self, section: 1),
            ]
        ) { indexPath, section, id in
            CellView(axis: .vertical, text: "Cell \(id.value)")
        } header: { _, _ in
            HeaderFooter(axis: .vertical, isHeader: true)
        } footer: { _, _ in
            HeaderFooter(axis: .vertical, isHeader: false)
        }
        .ignoresSafeArea()

        CollectionView(
            .compositional(
                axis: .horizontal,
                spacing: 12,
                pinnedViews: [.header]
            ),
            sections: [
                CollectionViewSection(items: [1, 2, 3], id: \.self, section: 0),
                CollectionViewSection(items: [4, 5, 6], id: \.self, section: 1),
            ]
        ) { indexPath, section, id in
            CellView(axis: .horizontal, text: "Cell \(id.value)")
        } header: { _, _ in
            HeaderFooter(axis: .horizontal, isHeader: true)
        } footer: { _, _ in
            HeaderFooter(axis: .horizontal, isHeader: false)
        }

        ScrollView {
            CollectionView(
                .compositional(
                    axis: .horizontal,
                    spacing: 12,
                    pinnedViews: [.header]
                ),
                sections: [
                    CollectionViewSection(items: [1, 2, 3], id: \.self, section: 0),
                    CollectionViewSection(items: [4, 5, 6], id: \.self, section: 1),
                ]
            ) { indexPath, section, id in
                CellView(axis: .horizontal, text: "Cell \(id.value)")
            } header: { _, _ in
                HeaderFooter(axis: .horizontal, isHeader: true)
            } footer: { _, _ in
                HeaderFooter(axis: .horizontal, isHeader: false)
            }
            .frame(height: 100)
        }

        CollectionView(
            .compositional(
                spacing: 12,
                pinnedViews: [.header]
            )
            .supplementaryViewVisibility(.visible(in: [0]), for: .custom("banner"))
            .supplementaryViewVisibility(.hidden(in: [0]), for: .custom("card")),
            sections: [
                CollectionViewSection(items: [1, 2, 3], id: \.self, section: 0),
                CollectionViewSection(items: [4, 5, 6], id: \.self, section: 1),
            ],
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
        ) { indexPath, section, id in
            CellView(axis: .vertical, text: "Cell \(id.value)")
        } header: { _, _ in
            HeaderFooter(axis: .vertical, isHeader: true)
        } footer: { _, _ in
            HeaderFooter(axis: .vertical, isHeader: false)
        } supplementaryView: { id, indexPath, index in
            Color.purple
                .overlay { Text(verbatim: "\(id)") }
                .frame(height: 100)
                .border(Color.pink, width: 5)
        }
        .ignoresSafeArea()
    }

    struct CellView: View {
        var axis: Axis
        var text: String

        var body: some View {
            Text(text)
                .frame(maxWidth: axis == .vertical ? .infinity : nil, maxHeight: axis == .horizontal ? .infinity : nil)
                .padding()
                .background(Color.primary.opacity(0.02))
        }
    }

    struct HeaderFooter: View {
        var axis: Axis
        var isHeader: Bool

        var body: some View {
            Text(isHeader ? "Header" : "Footer")
                .frame(maxWidth: axis == .vertical ? .infinity : nil, minHeight: 24, maxHeight: axis == .horizontal ? .infinity : nil)
                .background(Material.ultraThin)
        }
    }
}
#endif
