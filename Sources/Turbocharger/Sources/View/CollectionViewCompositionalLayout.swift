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
    public struct Configuration: Equatable {
        public var axis: Axis
        public var layoutSize: CollectionViewCompositionalLayoutSize?
        public var itemSpacing: CGFloat
        public var sectionSpacing: CGFloat
        public var contentInsets: EdgeInsets
        public var pinnedViews: Set<CollectionViewSupplementaryView.ID>
        public var supplementaryViewVisibility: [CollectionViewSupplementaryView.ID: CollectionViewSupplementaryViewVisibility]
        public var backgroundConfiguration: AnyCollectionViewBackgroundConfiguration?
        public var layoutAttributes: AnyCollectionViewLayoutAttributes?
    }

    public var configuration: Configuration
    public var showsIndicators: Bool
    public var safeAreaInsets: EdgeInsets?

    public init(
        axis: Axis = .vertical,
        showsIndicators: Bool = true,
        layoutSize: CollectionViewCompositionalLayoutSize? = nil,
        itemSpacing: CGFloat = 0,
        sectionSpacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        safeAreaInsets: EdgeInsets? = nil,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = [],
        supplementaryViewVisibility: [CollectionViewSupplementaryView.ID: CollectionViewSupplementaryViewVisibility] = [:]
    ) {
        self.configuration = Configuration(
            axis: axis,
            layoutSize: layoutSize,
            itemSpacing: itemSpacing,
            sectionSpacing: sectionSpacing,
            contentInsets: contentInsets,
            pinnedViews: pinnedViews,
            supplementaryViewVisibility: supplementaryViewVisibility,
            backgroundConfiguration: nil,
            layoutAttributes: nil
        )
        self.showsIndicators = showsIndicators
        self.safeAreaInsets = safeAreaInsets
    }

    #if os(iOS)
    public func makeUICollectionViewLayout(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> CollectionViewCompositionalLayoutImpl {
        let sectionProvider = CollectionViewCompositionalLayoutImpl.SectionProvider(
            configuration: configuration,
            options: options
        )
        let layout = CollectionViewCompositionalLayoutImpl(
            sectionProvider: sectionProvider,
            configuration: {
                let layoutConfiguration = UICollectionViewCompositionalLayoutConfiguration()
                layoutConfiguration.contentInsetsReference = .none
                layoutConfiguration.interSectionSpacing = configuration.sectionSpacing
                switch configuration.axis {
                case .vertical:
                    layoutConfiguration.scrollDirection = .vertical
                case .horizontal:
                    layoutConfiguration.scrollDirection = .horizontal
                }
                return layoutConfiguration
            }()
        )
        return layout
    }

    public func updateUICollectionViewLayout(
        _ collectionViewLayout: CollectionViewCompositionalLayoutImpl,
        context: Context,
        options: CollectionViewLayoutOptions
    ) {
        collectionViewLayout.sectionProvider.configuration = configuration
        collectionViewLayout.sectionProvider.options = options
        collectionViewLayout.configuration.interSectionSpacing = configuration.sectionSpacing
        switch configuration.axis {
        case .vertical:
            collectionViewLayout.configuration.scrollDirection = .vertical
        case .horizontal:
            collectionViewLayout.configuration.scrollDirection = .horizontal
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
        collectionView.showsVerticalScrollIndicator = showsIndicators
        collectionView.showsHorizontalScrollIndicator = showsIndicators

        let safeAreaInsets = safeAreaInsets.map {
            UIEdgeInsets(
                edgeInsets: $0,
                layoutDirection: context.environment.layoutDirection
            )
        } ?? .zero
        var contentInset = safeAreaInsets
        contentInset.top = max(0, safeAreaInsets.top - collectionView.safeAreaInsets.top)
        contentInset.bottom = max(0, safeAreaInsets.bottom - collectionView.safeAreaInsets.bottom)
        contentInset.left = max(0, safeAreaInsets.left - collectionView.safeAreaInsets.left)
        contentInset.right = max(0, safeAreaInsets.right - collectionView.safeAreaInsets.right)
        if collectionView.contentInset != contentInset {
            collectionView.contentInset = contentInset
            collectionView.scrollIndicatorInsets = contentInset
        }
    }

    public func updateUICollectionViewCell(
        _ collectionView: UICollectionView,
        cell: UICollectionViewCell,
        indexPath: IndexPath,
        context: Context
    ) {
        if let backgroundConfiguration = configuration.backgroundConfiguration {
            if #available(iOS 15.0, *) {
                cell.configurationUpdateHandler = { cell, state in
                    let configuration = backgroundConfiguration.makeConfiguration(for: .item, state: state)
                    cell.backgroundConfiguration = configuration
                }
            } else {
                let configuration = backgroundConfiguration.makeConfiguration(for: .item, state: cell.configurationState)
                cell.backgroundConfiguration = configuration
            }
        } else {
            cell.backgroundConfiguration = nil
        }
    }

    public func updateUICollectionViewSupplementaryView(
        _ collectionView: UICollectionView,
        supplementaryView: UICollectionViewCell,
        kind: String,
        indexPath: IndexPath,
        context: Context
    ) {
        if let backgroundConfiguration = configuration.backgroundConfiguration {
            let kind = CollectionViewLayoutElementKind.supplementaryView(.custom(kind))
            if #available(iOS 15.0, *) {
                supplementaryView.configurationUpdateHandler = { cell, state in
                    let configuration = backgroundConfiguration.makeConfiguration(for: kind, state: state)
                    cell.backgroundConfiguration = configuration
                }
            } else {
                let configuration = backgroundConfiguration.makeConfiguration(for: kind, state: supplementaryView.configurationState)
                supplementaryView.backgroundConfiguration = configuration
            }
        } else {
            supplementaryView.backgroundConfiguration = nil
        }
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
        copy.configuration.supplementaryViewVisibility[id] = visibility
        return copy
    }

    public func backgroundConfiguration<
        Configuration: CollectionViewBackgroundConfiguration
    >(
        _ configuration: Configuration
    ) -> CollectionViewCompositionalLayout {
        var copy = self
        copy.configuration.backgroundConfiguration = AnyCollectionViewBackgroundConfiguration(configuration)
        return copy
    }

    public func layoutAttributes<
        Attributes: CollectionViewLayoutAttributes
    >(
        _ layoutAttributes: Attributes
    ) -> CollectionViewCompositionalLayout {
        var copy = self
        copy.configuration.layoutAttributes = AnyCollectionViewLayoutAttributes(layoutAttributes)
        return copy
    }
}


#if os(iOS)
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public class CollectionViewCompositionalLayoutImpl: UICollectionViewCompositionalLayout {

    public class SectionProvider {
        public var configuration: CollectionViewCompositionalLayout.Configuration
        public var options: CollectionViewLayoutOptions

        public init(
            configuration: CollectionViewCompositionalLayout.Configuration,
            options: CollectionViewLayoutOptions
        ) {
            self.configuration = configuration
            self.options = options
        }

        @MainActor
        func makeSection(
            section: Int, environment: any NSCollectionLayoutEnvironment
        ) -> NSCollectionLayoutSection? {
            let itemSize: NSCollectionLayoutSize
            let widthDimension: NSCollectionLayoutDimension = configuration.axis == .vertical
                ? .fractionalWidth(1.0)
                : .estimated(300)
            let heightDimension: NSCollectionLayoutDimension = configuration.axis == .vertical
                ? .estimated(60)
                : .fractionalHeight(1.0)
            if let layoutSize = configuration.layoutSize {
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
                switch configuration.axis {
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
            let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
            layoutSection.interGroupSpacing = configuration.itemSpacing
            layoutSection.contentInsets = NSDirectionalEdgeInsets(configuration.contentInsets)
            if #available(iOS 16.0, *) {
                layoutSection.supplementaryContentInsetsReference = .none
            } else {
                layoutSection.supplementariesFollowContentInsets = false
            }
            for supplementaryView in options.supplementaryViews {
                let isVisible = {
                    guard
                        let visibility = configuration.supplementaryViewVisibility[supplementaryView.id]
                    else {
                        return true
                    }
                    return visibility.isVisible(in: section)
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
                item.pinToVisibleBounds = configuration.pinnedViews.contains(supplementaryView.id)
                layoutSection.boundarySupplementaryItems.append(item)
            }
            return layoutSection
        }
    }
    public var sectionProvider: SectionProvider

    public var layoutAttributes: AnyCollectionViewLayoutAttributes? {
        sectionProvider.configuration.layoutAttributes
    }

    public init(
        sectionProvider: SectionProvider,
        configuration: UICollectionViewCompositionalLayoutConfiguration
    ) {
        self.sectionProvider = sectionProvider
        super.init(
            sectionProvider: { [unowned sectionProvider] section, environment in
                sectionProvider.makeSection(section: section, environment: environment)
            },
            configuration: configuration
        )
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
extension CollectionViewLayout where Self == CollectionViewCompositionalLayout {

    public static var compositional: Self { .compositional() }

    public static func compositional(
        axis: Axis = .vertical,
        showsIndicators: Bool = true,
        layoutSize: CollectionViewCompositionalLayoutSize? = nil,
        spacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        safeAreaInsets: EdgeInsets? = nil,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = []
    ) -> Self {
        .compositional(
            axis: axis,
            showsIndicators: showsIndicators,
            layoutSize: layoutSize,
            itemSpacing: spacing,
            contentInsets: contentInsets,
            safeAreaInsets: safeAreaInsets,
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
        safeAreaInsets: EdgeInsets? = nil,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = []
    ) -> Self {
        CollectionViewCompositionalLayout(
            axis: axis,
            showsIndicators: showsIndicators,
            layoutSize: layoutSize,
            itemSpacing: itemSpacing,
            sectionSpacing: sectionSpacing,
            contentInsets: contentInsets,
            safeAreaInsets: safeAreaInsets,
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
