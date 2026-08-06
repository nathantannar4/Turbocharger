//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)

import UIKit
import SwiftUI
import Engine

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct CollectionViewCompositionalLayoutSize: Equatable {

    @frozen
    public enum Dimension: Equatable {
        case fractionalWidth(CGFloat)
        case fractionalHeight(CGFloat)
        case absolute(CGFloat)
        case estimated(CGFloat)

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

    public static var unspecified: CollectionViewCompositionalLayoutSize {
        CollectionViewCompositionalLayoutSize()
    }

    @MainActor
    func toUIKit(
        replacingUnspecifiedDimensionBy unspecified: NSCollectionLayoutSize
    ) -> NSCollectionLayoutSize {
        NSCollectionLayoutSize(
            widthDimension: width?.toUIKit() ?? unspecified.widthDimension,
            heightDimension: height?.toUIKit() ?? unspecified.heightDimension
        )
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct CollectionViewCompositionalLayoutGroup: Equatable {

    @frozen
    public enum OrthogonalScrollingBehavior: Equatable {
        case continuous
        case continuousGroupLeadingBoundary
        case paging
        case groupPaging
        case groupPagingCentered

        @MainActor
        func toUIKit() -> UICollectionLayoutSectionOrthogonalScrollingBehavior {
            switch self {
            case .continuous:
                return .continuous
            case .continuousGroupLeadingBoundary:
                return .continuousGroupLeadingBoundary
            case .paging:
                return .paging
            case .groupPaging:
                return .groupPaging
            case .groupPagingCentered:
                return .groupPagingCentered
            }
        }
    }

    @frozen
    public enum Spacing: Equatable {
        case fixed(CGFloat)
        case flexible(CGFloat)

        @MainActor
        func toUIKit() -> NSCollectionLayoutSpacing {
            switch self {
            case .fixed(let spacing):
                return .fixed(spacing)
            case .flexible(let spacing):
                return .flexible(spacing)
            }
        }
    }

    @frozen
    public struct EdgeSpacing: Equatable {
        public var top: Spacing?
        public var leading: Spacing?
        public var bottom: Spacing?
        public var trailing: Spacing?

        public init(
            top: Spacing? = nil,
            leading: Spacing? = nil,
            bottom: Spacing? = nil,
            trailing: Spacing? = nil
        ) {
            self.top = top
            self.leading = leading
            self.bottom = bottom
            self.trailing = trailing
        }

        @MainActor
        func toUIKit() -> NSCollectionLayoutEdgeSpacing {
            NSCollectionLayoutEdgeSpacing(
                leading: leading?.toUIKit(),
                top: top?.toUIKit(),
                trailing: trailing?.toUIKit(),
                bottom: bottom?.toUIKit()
            )
        }
    }

    @usableFromInline
    enum Storage: Equatable {
        case item(CollectionViewCompositionalLayoutSize)

        @usableFromInline
        struct GroupedStorage: Equatable {
            var axis: Axis?
            var spacing: Spacing?
            var edgeSpacing: EdgeSpacing?
            var scrollingBehaviour: OrthogonalScrollingBehavior?
            var bounces: Bool?
            var groupSize: CollectionViewCompositionalLayoutSize
            var itemSizes: [CollectionViewCompositionalLayoutSize]
            var contentInsets: EdgeInsets
        }
        case grouped(GroupedStorage)

        @usableFromInline
        struct ListStorage: Equatable {
            var configuration: CollectionViewListLayout.Configuration
        }
        case list(ListStorage)
    }

    @usableFromInline
    var storage: Storage

    public static var unspecified: CollectionViewCompositionalLayoutGroup {
        .item(.unspecified)
    }

    public static func item(
        _ size: CollectionViewCompositionalLayoutSize
    ) -> CollectionViewCompositionalLayoutGroup {
        CollectionViewCompositionalLayoutGroup(storage: .item(size))
    }

    public static func grouped(
        axis: Axis? = nil,
        spacing: Spacing? = nil,
        edgeSpacing: EdgeSpacing? = nil,
        scrollingBehaviour: OrthogonalScrollingBehavior? = nil,
        bounces: Bool? = nil,
        groupSize: CollectionViewCompositionalLayoutSize,
        itemSize: CollectionViewCompositionalLayoutSize,
        count: Int,
        contentInsets: EdgeInsets = .zero
    ) -> CollectionViewCompositionalLayoutGroup {
        grouped(
            axis: axis,
            spacing: spacing,
            edgeSpacing: edgeSpacing,
            scrollingBehaviour: scrollingBehaviour,
            bounces: bounces,
            groupSize: groupSize,
            itemSizes: Array(repeating: itemSize, count: count),
            contentInsets: contentInsets
        )
    }

    public static func grouped(
        axis: Axis? = nil,
        spacing: Spacing? = nil,
        edgeSpacing: EdgeSpacing? = nil,
        scrollingBehaviour: OrthogonalScrollingBehavior? = nil,
        bounces: Bool? = nil,
        groupSize: CollectionViewCompositionalLayoutSize,
        itemSizes: [CollectionViewCompositionalLayoutSize],
        contentInsets: EdgeInsets = .zero
    ) -> CollectionViewCompositionalLayoutGroup {
        CollectionViewCompositionalLayoutGroup(
            storage: .grouped(
                .init(
                    axis: axis,
                    spacing: spacing,
                    edgeSpacing: edgeSpacing,
                    scrollingBehaviour: scrollingBehaviour,
                    bounces: bounces,
                    groupSize: groupSize,
                    itemSizes: itemSizes,
                    contentInsets: contentInsets
                )
            )
        )
    }

    #if os(tvOS)
    public static func list(
        appearance: CollectionViewListLayoutAppearance,
        headerTopPadding: CGFloat? = nil,
        backgroundColor: Color? = nil
    ) -> CollectionViewCompositionalLayoutGroup {
        CollectionViewCompositionalLayoutGroup(
            storage: .list(
                .init(
                    configuration: CollectionViewListLayout.Configuration(
                        appearance: appearance,
                        headerTopPadding: headerTopPadding,
                        backgroundColor: backgroundColor
                    )
                )
            )
        )
    }
    #else
    @_disfavoredOverload
    public static func list(
        appearance: CollectionViewListLayoutAppearance,
        showsSeparators: Bool = true,
        separatorConfiguration: CollectionViewListLayoutSeparatorConfiguration? = nil,
        headerTopPadding: CGFloat? = nil,
        backgroundColor: Color? = nil,
        leadingSwipeActionsConfiguration: (any CollectionViewCellSwipeActionsConfiguration)? = nil,
        trailingSwipeActionsConfiguration: (any CollectionViewCellSwipeActionsConfiguration)? = nil
    ) -> CollectionViewCompositionalLayoutGroup {
        .list(
            appearance: appearance,
            showsSeparators: showsSeparators,
            separatorConfiguration: separatorConfiguration,
            headerTopPadding: headerTopPadding,
            backgroundColor: backgroundColor,
            leadingSwipeActionsConfiguration: leadingSwipeActionsConfiguration.map { AnyCollectionViewCellSwipeActionsConfiguration($0) },
            trailingSwipeActionsConfiguration: trailingSwipeActionsConfiguration.map { AnyCollectionViewCellSwipeActionsConfiguration($0) }
        )
    }

    public static func list(
        appearance: CollectionViewListLayoutAppearance,
        showsSeparators: Bool = true,
        separatorConfiguration: CollectionViewListLayoutSeparatorConfiguration? = nil,
        headerTopPadding: CGFloat? = nil,
        backgroundColor: Color? = nil,
        leadingSwipeActionsConfiguration: AnyCollectionViewCellSwipeActionsConfiguration? = nil,
        trailingSwipeActionsConfiguration: AnyCollectionViewCellSwipeActionsConfiguration? = nil
    ) -> CollectionViewCompositionalLayoutGroup {
        CollectionViewCompositionalLayoutGroup(
            storage: .list(
                .init(
                    configuration: CollectionViewListLayout.Configuration(
                        appearance: appearance,
                        showsSeparators: showsSeparators,
                        separatorConfiguration: separatorConfiguration,
                        headerTopPadding: headerTopPadding,
                        backgroundColor: backgroundColor,
                        leadingSwipeActionsConfiguration: leadingSwipeActionsConfiguration,
                        trailingSwipeActionsConfiguration: trailingSwipeActionsConfiguration
                    )
                )
            )
        )
    }
    #endif

    @MainActor
    func toUIKit(
        axis: Axis,
        replacingUnspecifiedDimensionBy unspecified: NSCollectionLayoutSize,
        context: CollectionViewLayoutContext,
        layoutEnvironment: any NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        switch storage {
        case .item(let itemSize):
            let layoutSize = itemSize.toUIKit(
                replacingUnspecifiedDimensionBy: unspecified
            )
            let group: NSCollectionLayoutGroup
            switch axis {
            case .vertical:
                group = NSCollectionLayoutGroup.vertical(
                    layoutSize: layoutSize,
                    subitems: [
                        NSCollectionLayoutItem(layoutSize: layoutSize)
                    ]
                )
            case .horizontal:
                group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: layoutSize,
                    subitems: [
                        NSCollectionLayoutItem(layoutSize: layoutSize)
                    ]
                )
            }
            let section = NSCollectionLayoutSection(group: group)
            return section

        case .grouped(let storage):
            let group: NSCollectionLayoutGroup
            switch (storage.axis ?? axis) {
            case .vertical:
                group = NSCollectionLayoutGroup.vertical(
                    layoutSize: storage.groupSize.toUIKit(
                        replacingUnspecifiedDimensionBy: unspecified
                    ),
                    subitems: storage.itemSizes.map {
                        NSCollectionLayoutItem(
                            layoutSize: $0.toUIKit(replacingUnspecifiedDimensionBy: unspecified)
                        )
                    }
                )
            case .horizontal:
                group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: storage.groupSize.toUIKit(
                        replacingUnspecifiedDimensionBy: unspecified
                    ),
                    subitems: storage.itemSizes.map {
                        NSCollectionLayoutItem(
                            layoutSize: $0.toUIKit(replacingUnspecifiedDimensionBy: unspecified)
                        )
                    }
                )
            }
            group.interItemSpacing = storage.spacing?.toUIKit()
            group.edgeSpacing = storage.edgeSpacing?.toUIKit()
            group.contentInsets = NSDirectionalEdgeInsets(storage.contentInsets)
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = storage.scrollingBehaviour?.toUIKit() ?? .none
            if #available(iOS 17.0, tvOS 17.0, *) {
                section.orthogonalScrollingProperties.bounce = storage.bounces
                    .map { $0 ? .always : .never } ?? .automatic
            }
            return section

        case .list(let storage):
            var configuration = storage.configuration.toUIKit(context: context)
            configuration.headerMode = .none
            configuration.footerMode = .none
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            return section

        }
    }
}

/// A ``CollectionViewLayout``
@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct CollectionViewCompositionalLayout: CollectionViewLayout {

    @frozen
    public struct Configuration: Equatable {
        public var axis: Axis
        public var layoutGroup: CollectionViewCompositionalLayoutGroup
        public var itemSpacing: CGFloat
        public var sectionSpacing: CGFloat
        public var contentInsets: EdgeInsets
        public var pinnedViews: Set<CollectionViewSupplementaryView.ID>
        public var supplementaryViewVisibility: [CollectionViewSupplementaryView.ID: CollectionViewSupplementaryViewVisibility]
        public var scrollEffect: AnyCollectionViewVisibleItemsScrollEffect?
    }

    public var configuration: Configuration
    public var showsIndicators: Bool
    public var backgroundColor: Color?
    public var backgroundConfiguration: AnyCollectionViewBackgroundConfiguration?
    public var layoutAttributes: (any CollectionViewLayoutAttributes)?

    public init(
        axis: Axis = .vertical,
        showsIndicators: Bool = true,
        layoutGroup: CollectionViewCompositionalLayoutGroup,
        itemSpacing: CGFloat = 0,
        sectionSpacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = [],
        supplementaryViewVisibility: [CollectionViewSupplementaryView.ID: CollectionViewSupplementaryViewVisibility] = [:],
        backgroundColor: Color? = nil,
    ) {
        self.configuration = Configuration(
            axis: axis,
            layoutGroup: layoutGroup,
            itemSpacing: itemSpacing,
            sectionSpacing: sectionSpacing,
            contentInsets: contentInsets,
            pinnedViews: pinnedViews,
            supplementaryViewVisibility: supplementaryViewVisibility
        )
        self.showsIndicators = showsIndicators
        self.backgroundColor = backgroundColor
    }

    public func makeUICollectionViewLayout(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> CollectionViewCompositionalLayoutImpl {
        let sectionProvider = CollectionViewCompositionalLayoutImpl.SectionProvider(
            configuration: configuration,
            options: options,
            context: context,
            layoutAttributes: layoutAttributes
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
        collectionViewLayout.sectionProvider.context = context
        collectionViewLayout.sectionProvider.layoutAttributes = layoutAttributes
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
        #if os(iOS)
        uiCollectionView.keyboardDismissMode = .interactive
        #endif
        return uiCollectionView
    }

    public func updateUICollectionView(
        _ collectionView: UICollectionView,
        context: Context
    ) {
        collectionView.showsVerticalScrollIndicator = showsIndicators
        collectionView.showsHorizontalScrollIndicator = showsIndicators
        collectionView.backgroundColor = backgroundColor?.toUIColor(in: context.environment)
    }

    public func updateUICollectionViewCell(
        _ collectionView: UICollectionView,
        cell: UICollectionViewCell,
        indexPath: IndexPath,
        context: Context
    ) {
        if let backgroundConfiguration = backgroundConfiguration {
            let configuration = backgroundConfiguration.makeConfiguration(
                for: .item,
                indexPath: indexPath,
                state: cell.configurationState,
                context: context
            )
            cell.backgroundConfiguration = configuration
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
        if let backgroundConfiguration = backgroundConfiguration {
            let kind = CollectionViewLayoutElementKind.supplementaryView(.custom(kind))
            let configuration = backgroundConfiguration.makeConfiguration(
                for: kind,
                indexPath: indexPath,
                state: supplementaryView.configurationState,
                context: context
            )
            supplementaryView.backgroundConfiguration = configuration
        } else {
            supplementaryView.backgroundConfiguration = nil
        }
    }
}

@available(iOS 14.0, tvOS 14.0, *)
extension CollectionViewCompositionalLayout {

    public func supplementaryViewVisibility(
        _ visibility: CollectionViewSupplementaryViewVisibility,
        for id: CollectionViewSupplementaryView.ID
    ) -> CollectionViewCompositionalLayout {
        var copy = self
        copy.configuration.supplementaryViewVisibility[id] = visibility
        return copy
    }

    public func backgroundColor(
        _ color: Color?
    ) -> CollectionViewCompositionalLayout {
        var copy = self
        copy.backgroundColor = color
        return copy
    }

    public func backgroundConfiguration<
        Configuration: CollectionViewBackgroundConfiguration
    >(
        _ configuration: Configuration
    ) -> CollectionViewCompositionalLayout {
        var copy = self
        copy.backgroundConfiguration = AnyCollectionViewBackgroundConfiguration(configuration)
        return copy
    }

    public func layoutAttributes<
        Attributes: CollectionViewLayoutAttributes
    >(
        _ layoutAttributes: Attributes
    ) -> CollectionViewCompositionalLayout {
        var copy = self
        copy.layoutAttributes = layoutAttributes
        return copy
    }

    public func scrollEffect<
        ScrollEffect: CollectionViewVisibleItemsScrollEffect
    >(
        _ scrollEffect: ScrollEffect
    ) -> CollectionViewCompositionalLayout {
        var copy = self
        copy.configuration.scrollEffect = AnyCollectionViewVisibleItemsScrollEffect(scrollEffect)
        return copy
    }

    public init(
        axis: Axis = .vertical,
        showsIndicators: Bool = true,
        layoutSize: CollectionViewCompositionalLayoutSize = .unspecified,
        itemSpacing: CGFloat = 0,
        sectionSpacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = [],
        supplementaryViewVisibility: [CollectionViewSupplementaryView.ID: CollectionViewSupplementaryViewVisibility] = [:]
    ) {
        self.init(
            axis: axis,
            showsIndicators: showsIndicators,
            layoutGroup: .item(layoutSize),
            itemSpacing: itemSpacing,
            sectionSpacing: sectionSpacing,
            contentInsets: contentInsets,
            pinnedViews: pinnedViews,
            supplementaryViewVisibility: supplementaryViewVisibility
        )
    }
}

@available(iOS 14.0, tvOS 14.0, *)
public class CollectionViewCompositionalLayoutImpl: UICollectionViewCompositionalLayout {

    public class SectionProvider {
        public var configuration: CollectionViewCompositionalLayout.Configuration
        public var options: CollectionViewLayoutOptions
        public var layoutAttributes: (any CollectionViewLayoutAttributes)?
        public var context: CollectionViewLayoutContext

        public init(
            configuration: CollectionViewCompositionalLayout.Configuration,
            options: CollectionViewLayoutOptions,
            context: CollectionViewLayoutContext,
            layoutAttributes: (any CollectionViewLayoutAttributes)?
        ) {
            self.configuration = configuration
            self.options = options
            self.context = context
            self.layoutAttributes = layoutAttributes
        }

        @MainActor
        func makeSection(
            section: Int,
            environment: any NSCollectionLayoutEnvironment
        ) -> NSCollectionLayoutSection? {
            let widthDimension: NSCollectionLayoutDimension = configuration.axis == .vertical
                ? .fractionalWidth(1.0)
                : .estimated(100)
            let heightDimension: NSCollectionLayoutDimension = configuration.axis == .vertical
                ? .estimated(100)
                : .fractionalHeight(1.0)
            let unspecifiedDimension = NSCollectionLayoutSize(
                widthDimension: widthDimension,
                heightDimension: heightDimension
            )
            let layoutGroup = configuration.layoutGroup
            let layoutSection = layoutGroup.toUIKit(
                axis: configuration.axis,
                replacingUnspecifiedDimensionBy: unspecifiedDimension,
                context: context,
                layoutEnvironment: environment
            )
            layoutSection.interGroupSpacing = configuration.itemSpacing
            layoutSection.contentInsets = NSDirectionalEdgeInsets(configuration.contentInsets)
            if #available(iOS 16.0, tvOS 16.0, *) {
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
                let item = supplementaryView.toUIKit(unspecifiedDimension: unspecifiedDimension)
                item.pinToVisibleBounds = configuration.pinnedViews.contains(supplementaryView.id)
                layoutSection.boundarySupplementaryItems.append(item)
            }
            if let scrollEffect = configuration.scrollEffect {
                layoutSection.visibleItemsInvalidationHandler = { [unowned self] visibleItems, offset, environment in
                    scrollEffect.onScroll(
                        visibleItem: visibleItems,
                        contentOffset: offset,
                        environment: environment,
                        context: context
                    )
                }
            }
            return layoutSection
        }
    }
    public var sectionProvider: SectionProvider

    public var layoutAttributes: (any CollectionViewLayoutAttributes)? {
        sectionProvider.layoutAttributes
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

@available(iOS 14.0, tvOS 14.0, *)
extension CollectionViewLayout where Self == CollectionViewCompositionalLayout {

    public static var compositional: Self { .compositional() }

    public static func compositional(
        axis: Axis = .vertical,
        showsIndicators: Bool = true,
        layoutSize: CollectionViewCompositionalLayoutSize = .unspecified,
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
        layoutSize: CollectionViewCompositionalLayoutSize = .unspecified,
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

    public static func compositional(
        axis: Axis = .vertical,
        showsIndicators: Bool = true,
        layoutGroup: CollectionViewCompositionalLayoutGroup,
        itemSpacing: CGFloat = 0,
        sectionSpacing: CGFloat = 0,
        contentInsets: EdgeInsets = .zero,
        pinnedViews: Set<CollectionViewSupplementaryView.ID> = []
    ) -> Self {
        CollectionViewCompositionalLayout(
            axis: axis,
            showsIndicators: showsIndicators,
            layoutGroup: layoutGroup,
            itemSpacing: itemSpacing,
            sectionSpacing: sectionSpacing,
            contentInsets: contentInsets,
            pinnedViews: pinnedViews
        )
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CollectionViewLayout_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            CollectionView(
                .compositional(
                    layoutGroup: .list(
                        appearance: .plain
                    )
                ),
                sections: [
                    CollectionViewSection(items: [1, 2, 3], id: \.self, section: 0)
                ],
                supplementaryViews: [
                    .custom(
                        "bottomContent",
                        alignment: .bottom,
                        offset: CGPoint(x: 0, y: 24)
                    )
                ]
            ) { indexPath, section, id in
                CellView(axis: .vertical, text: "Cell \(id.value)")
            } header: { _, _ in
                HeaderFooter(axis: .vertical, label: "Header")
            } footer: { _, _ in
                HeaderFooter(axis: .vertical, label: "Footer")
            } supplementaryView: { _, _, _ in
                HeaderFooter(axis: .vertical, label: "SupplementaryView")
            }
            .ignoresSafeArea()
        }

        ZStack {
            CollectionView(
                .compositional(
                    spacing: 12,
                    pinnedViews: [.header]
                ),
                sections: [
                    CollectionViewSection(items: [1, 2, 3], id: \.self, section: 0),
                    CollectionViewSection(items: [4, 5, 6], id: \.self, section: 1),
                ]
            ) { indexPath, section, id in
                CellView(axis: .vertical, text: "Cell \(id.value)")
            } header: { _, _ in
                HeaderFooter(axis: .vertical, label: "Header")
            } footer: { _, _ in
                HeaderFooter(axis: .vertical, label: "Footer")
            }
            .ignoresSafeArea()
        }

        ZStack {
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
                HeaderFooter(axis: .vertical, label: "Header")
            } footer: { _, _ in
                HeaderFooter(axis: .vertical, label: "Footer")
            }
            .ignoresSafeArea()
        }

        ZStack {
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
                HeaderFooter(axis: .horizontal, label: "Header")
            } footer: { _, _ in
                HeaderFooter(axis: .horizontal, label: "Footer")
            }
        }

        ScrollView {
            VStack {
                CollectionView(
                    .compositional(
                        axis: .horizontal,
                        layoutGroup: .grouped(
                            axis: .vertical,
                            spacing: .fixed(12),
                            scrollingBehaviour: .groupPaging,
                            groupSize: .init(
                                width: .fractionalWidth(1.0),
                                height: .fractionalHeight(1.0)
                            ),
                            itemSize: .init(
                                width: .fractionalWidth(1.0),
                                height: .fractionalHeight(1.0 / 3)
                            ),
                            count: 3
                        ),
                        itemSpacing: 12,
                        sectionSpacing: 12,
                        pinnedViews: [.header]
                    ),
                    sections: [
                        CollectionViewSection(items: [1, 2, 3, 4, 5, 6, 7, 8], id: \.self, section: 0),
                        CollectionViewSection(items: [9, 10], id: \.self, section: 1),
                    ]
                ) { indexPath, section, id in
                    Color.blue
                        .overlay {
                            Text("Cell \(id.value)")
                                .foregroundColor(.white)
                        }
                } header: { _, _ in
                    HeaderFooter(axis: .vertical, label: "Header")
                } footer: { _, _ in
                    HeaderFooter(axis: .vertical, label: "Footer")
                }
                .frame(height: 300)

                let rows: Int = 4
                CollectionView(
                    .compositional(
                        axis: .vertical,
                        layoutGroup: .grouped(
                            axis: .vertical,
                            spacing: .fixed(12),
                            scrollingBehaviour: .groupPaging,
                            groupSize: .init(
                                width: .fractionalWidth(1.0),
                                height: .fractionalHeight(1.0)
                            ),
                            itemSize: .init(
                                width: .fractionalWidth(1.0),
                                height: .fractionalHeight(1.0 / CGFloat(rows))
                            ),
                            count: rows,
                            contentInsets: EdgeInsets(
                                top: 0,
                                leading: 12,
                                bottom: 0,
                                trailing: 60
                            )
                        ),
                        itemSpacing: -60,
                        sectionSpacing: 12
                    ),
                    sections: [
                        CollectionViewSection(items: 0...13, id: \.self, section: 0),
                    ]
                ) { indexPath, section, id in
                    Color.blue
                        .overlay {
                            Text("Cell \(id.value)")
                                .foregroundColor(.white)
                        }
                }
                .frame(height: 300)
            }
        }

        ZStack {
            CollectionView(
                .compositional(
                    axis: .horizontal,
                    layoutGroup: .item(
                        CollectionViewCompositionalLayoutSize(
                            width: .fractionalHeight(1.0),
                            height: .fractionalHeight(1.0)
                        )
                    ),
                    itemSpacing: 12,
                    sectionSpacing: 12
                ),
                sections: [
                    CollectionViewSection(items: 0...5, id: \.self, section: 0),
                    CollectionViewSection(items: 6...12, id: \.self, section: 1),
                ]
            ) { indexPath, section, id in
                Color.blue
                    .overlay {
                        Text("Cell \(id.value)")
                            .foregroundColor(.white)
                    }
            }
            .frame(height: 100)
        }

        ZStack {
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
                HeaderFooter(axis: .vertical, label: "Header")
            } footer: { _, _ in
                HeaderFooter(axis: .vertical, label: "Footer")
            } supplementaryView: { _, _, _ in
                HeaderFooter(axis: .vertical, label: "SupplementaryView")
            }
            .ignoresSafeArea()
        }
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
        var label: String

        var body: some View {
            Text(label)
                .frame(maxWidth: axis == .vertical ? .infinity : nil, minHeight: 24, maxHeight: axis == .horizontal ? .infinity : nil)
                .background(Material.ultraThin)
        }
    }
}

#endif
