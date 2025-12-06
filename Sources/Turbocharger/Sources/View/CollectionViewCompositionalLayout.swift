//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

public struct CollectionViewCompositionalLayoutSize: Equatable, Sendable {
    public enum Dimension: Equatable, Sendable {
        case fractionalWidth(CGFloat)
        case fractionalHeight(CGFloat)
        case absolute(CGFloat)
        case estimated(CGFloat)

        #if os(iOS)
        @MainActor
        func toUIKit() -> NSCollectionLayoutDimension {
            switch self {
            case .fractionalWidth(let value):
                return .fractionalWidth(value)
            case .fractionalHeight(let value):
                return .fractionalHeight(value)
            case .absolute(let value):
                return .absolute(value)
            case .estimated(let value):
                return .estimated(value)
            }
        }
        #endif
    }

    public var width: Dimension?
    public var height: Dimension?

    public init(
        width: Dimension? = nil,
        height: Dimension? = nil
    ) {
        self.width = width
        self.height = height
    }
}

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
    public var layoutSize: CollectionViewCompositionalLayoutSize?
    public var itemSpacing: CGFloat
    public var sectionSpacing: CGFloat
    public var contentInsets: EdgeInsets
    public var pinnedViews: Set<CollectionViewSupplementaryView.ID>
    public var supplementaryViewVisibility: [CollectionViewSupplementaryView.ID: CollectionViewSupplementaryViewVisibility]
    public var layoutAttributes: AnyCollectionViewLayoutAttributes?

    @inlinable
    public init(
        axis: Axis = .vertical,
        showsIndicators: Bool = true,
        layoutSize: CollectionViewCompositionalLayoutSize? = nil,
        itemSpacing: CGFloat = 0,
        sectionSpacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = [],
        supplementaryViewVisibility: [CollectionViewSupplementaryView.ID: CollectionViewSupplementaryViewVisibility] = [:]
    ) {
        self.axis = axis
        self.showsIndicators = showsIndicators
        self.layoutSize = layoutSize
        self.itemSpacing = itemSpacing
        self.sectionSpacing = sectionSpacing
        self.contentInsets = contentInsets
        self.pinnedViews = pinnedViews
        self.supplementaryViewVisibility = supplementaryViewVisibility
    }

    @inlinable
    public init<Attributes: CollectionViewLayoutAttributes>(
        axis: Axis = .vertical,
        showsIndicators: Bool = true,
        layoutSize: CollectionViewCompositionalLayoutSize? = nil,
        itemSpacing: CGFloat = 0,
        sectionSpacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = [],
        supplementaryViewVisibility: [CollectionViewSupplementaryView.ID: CollectionViewSupplementaryViewVisibility] = [:],
        layoutAttributes: Attributes
    ) {
        self.axis = axis
        self.showsIndicators = showsIndicators
        self.layoutSize = layoutSize
        self.itemSpacing = itemSpacing
        self.sectionSpacing = sectionSpacing
        self.contentInsets = contentInsets
        self.pinnedViews = pinnedViews
        self.supplementaryViewVisibility = supplementaryViewVisibility
        self.layoutAttributes = AnyCollectionViewLayoutAttributes(layoutAttributes)
    }

    #if os(iOS)
    public func makeUICollectionViewLayout(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionViewCompositionalLayout {
        let itemSize: NSCollectionLayoutSize
        let widthDimension: NSCollectionLayoutDimension = axis == .vertical
            ? .fractionalWidth(1.0)
            : .estimated(300)
        let heightDimension: NSCollectionLayoutDimension = axis == .vertical
            ? .estimated(60)
            : .fractionalHeight(1.0)
        if let layoutSize {
            itemSize = NSCollectionLayoutSize(
                widthDimension: layoutSize.width?.toUIKit() ?? widthDimension,
                heightDimension: layoutSize.height?.toUIKit() ?? heightDimension
            )
        } else {
            itemSize = NSCollectionLayoutSize(
                widthDimension: widthDimension,
                heightDimension: heightDimension
            )
        }

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
        configuration.contentInsetsReference = .none
        configuration.interSectionSpacing = sectionSpacing
        switch axis {
        case .vertical:
            configuration.scrollDirection = .vertical
        case .horizontal:
            configuration.scrollDirection = .horizontal
        }
        let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { section, environment in
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
                let supplementaryItemSize: NSCollectionLayoutSize
                if let layoutSize = supplementaryView.layoutSize {
                    supplementaryItemSize = NSCollectionLayoutSize(
                        widthDimension: layoutSize.width?.toUIKit() ?? itemSize.widthDimension,
                        heightDimension: layoutSize.height?.toUIKit() ?? itemSize.heightDimension
                    )
                } else {
                    supplementaryItemSize = itemSize
                }
                let item = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: supplementaryItemSize,
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
                item.extendsBoundary = supplementaryView.extendsBoundary
                item.contentInsets = NSDirectionalEdgeInsets(supplementaryView.contentInset)
                item.zIndex = supplementaryView.zIndex
                item.pinToVisibleBounds = pinnedViews.contains(supplementaryView.id)
                layoutSection.boundarySupplementaryItems.append(item)
            }
            return layoutSection
        }

        if let layoutAttributes {
            let layout = CollectionViewCompositionalLayoutImpl(
                layoutAttributes: layoutAttributes,
                sectionProvider: sectionProvider,
                configuration: configuration
            )
            return layout
        } else {
            let layout = UICollectionViewCompositionalLayout(
                sectionProvider: sectionProvider,
                configuration: configuration
            )
            return layout
        }
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
        if let layout = collectionView.collectionViewLayout as? CollectionViewCompositionalLayoutImpl {
            layout.layoutAttributes = layoutAttributes
        }
        collectionView.showsVerticalScrollIndicator = showsIndicators
        collectionView.showsHorizontalScrollIndicator = showsIndicators
    }
    #endif
}

#if os(iOS)
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public class CollectionViewCompositionalLayoutImpl: UICollectionViewCompositionalLayout {

    public var layoutAttributes: AnyCollectionViewLayoutAttributes? {
        didSet {
            guard oldValue != layoutAttributes else { return }
            invalidateLayout()
        }
    }

    public init(
        layoutAttributes: AnyCollectionViewLayoutAttributes,
        sectionProvider: @escaping UICollectionViewCompositionalLayoutSectionProvider,
        configuration: UICollectionViewCompositionalLayoutConfiguration
    ) {
        self.layoutAttributes = layoutAttributes
        super.init(sectionProvider: sectionProvider, configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {
        guard
            var attributes = super.layoutAttributesForElements(in: rect)
        else {
            return nil
        }
        guard let layoutAttributes else { return attributes }
        for index in attributes.indices {
            switch attributes[index].representedElementCategory {
            case .cell:
                layoutAttributes.layoutAttributes(
                    for: .item,
                    at: attributes[index].indexPath,
                    layout: self,
                    attributes: &attributes[index]
                )
            case .supplementaryView:
                guard let kind = attributes[index].representedElementKind else { continue }
                layoutAttributes.layoutAttributes(
                    for: .supplementaryView(.init(kind)),
                    at: attributes[index].indexPath,
                    layout: self,
                    attributes: &attributes[index]
                )
            case .decorationView:
                break
            @unknown default:
                break
            }
        }
        return attributes
    }

    open override func initialLayoutAttributesForAppearingItem(
        at itemIndexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard
            var attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        else {
            return nil
        }
        guard let layoutAttributes else { return attributes }
        layoutAttributes.initialAppearingLayoutAttributes(
            for: .item,
            at: itemIndexPath,
            layout: self,
            attributes: &attributes
        )
        return attributes
    }

    open override func finalLayoutAttributesForDisappearingItem(
        at itemIndexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard
            var attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        else {
            return nil
        }
        guard let layoutAttributes else { return attributes }
        layoutAttributes.finalDisappearingLayoutAttributes(
            for: .item,
            at: itemIndexPath,
            layout: self,
            attributes: &attributes
        )
        return attributes
    }

    open override func layoutAttributesForItem(
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard
            var attributes = super.layoutAttributesForItem(at: indexPath)
        else {
            return nil
        }
        guard let layoutAttributes else { return attributes }
        layoutAttributes.layoutAttributes(
            for: .item,
            at: indexPath,
            layout: self,
            attributes: &attributes
        )
        return attributes
    }

    open override func initialLayoutAttributesForAppearingSupplementaryElement(
        ofKind elementKind: String,
        at elementIndexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard
            var attributes = super.initialLayoutAttributesForAppearingSupplementaryElement(
                ofKind: elementKind,
                at: elementIndexPath
            )
        else {
            return nil
        }
        guard let layoutAttributes else { return attributes }
        layoutAttributes.initialAppearingLayoutAttributes(
            for: .supplementaryView(.init(elementKind)),
            at: elementIndexPath,
            layout: self,
            attributes: &attributes
        )
        return attributes
    }

    open override func finalLayoutAttributesForDisappearingSupplementaryElement(
        ofKind elementKind: String,
        at elementIndexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard
            var attributes = super.finalLayoutAttributesForDisappearingSupplementaryElement(
                ofKind: elementKind,
                at: elementIndexPath
            )
        else {
            return nil
        }
        guard let layoutAttributes else { return attributes }
        layoutAttributes.finalDisappearingLayoutAttributes(
            for: .supplementaryView(.init(elementKind)),
            at: elementIndexPath,
            layout: self,
            attributes: &attributes
        )
        return attributes
    }

    open override func layoutAttributesForSupplementaryView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard
            var attributes = super.layoutAttributesForSupplementaryView(
                ofKind: elementKind,
                at: indexPath
            )
        else {
            return nil
        }
        guard let layoutAttributes else { return attributes }
        layoutAttributes.layoutAttributes(
            for: .supplementaryView(.init(elementKind)),
            at: indexPath,
            layout: self,
            attributes: &attributes
        )
        return attributes
    }
}
#endif

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

    public static var compositional: Self { .compositional() }

    public static func compositional(
        axis: Axis = .vertical,
        showsIndicators: Bool = true,
        layoutSize: CollectionViewCompositionalLayoutSize? = nil,
        spacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = []
    ) -> Self {
        .compositional(
            axis: axis,
            showsIndicators: showsIndicators,
            layoutSize: layoutSize,
            itemSpacing: spacing,
            contentInsets: contentInsets,
            pinnedViews: pinnedViews
        )
    }

    public static func compositional(
        axis: Axis = .vertical,
        showsIndicators: Bool = true,
        layoutSize: CollectionViewCompositionalLayoutSize? = nil,
        itemSpacing: CGFloat = 0,
        sectionSpacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = []
    ) -> Self {
        CollectionViewCompositionalLayout(
            axis: axis,
            showsIndicators: showsIndicators,
            layoutSize: layoutSize,
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
