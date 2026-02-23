//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI
import Combine
import Engine

/// A `UICollectionViewDiffableDataSource` wrapper
@MainActor
@available(iOS 14.0, *)
open class CollectionViewCoordinator<
    Layout: CollectionViewLayout,
    Section: Equatable & Identifiable,
    Items: RandomAccessCollection
>: NSObject,
    UICollectionViewDelegate,
    UICollectionViewDragDelegate,
    UICollectionViewDropDelegate,
    UICollectionViewDataSourcePrefetching
where
    Items.Index: Hashable & Sendable,
    Items.Element: Equatable & Identifiable,
    Items.Element.ID: Equatable & Sendable,
    Section.ID: Equatable & Sendable
{
    public typealias ID = Items.Element.ID

    public var axis: Axis.Set { collectionView.axis }
    public var context: CollectionViewLayoutContext = .init(environment: .init(), transaction: .init())
    public private(set) var layout: Layout
    public private(set) var layoutOptions: CollectionViewLayoutOptions
    public private(set) var sections: [CollectionViewSection<Section, Items>]
    public private(set) var dataSource: UICollectionViewDiffableDataSource<Section.ID, ID>!
    public private(set) weak var collectionView: Layout.UICollectionViewType!

    public var onSelect: ((IndexPath, Items.Element) -> Void)?
    public var canSelect: ((IndexPath, Items.Element) -> CollectionViewSelectionAvailability)?

    public var onRefresh: (@MainActor @Sendable () async -> Void)? {
        didSet {
            configureRefreshControl()
        }
    }
    private var refreshTask: Task<Void, Never>?

    public var onItemWillAppear: ((IndexPath, CollectionViewSection<Section, Items>, Items.Element) -> Void)?

    public var dataPrefetcher: (any CollectionViewDataPrefetcher<Items.Element>)?

    public var onReorder: ((_ from: (Int, IndexSet), _ to: (Int, Int)) -> Void)? {
        didSet {
            let isEnabled = onReorder != nil
            guard isEnabled != collectionView.dragInteractionEnabled else { return }
            collectionView.dragInteractionEnabled = isEnabled
        }
    }

    public var onScroll: ((EdgeInsets, CGPoint) -> Void)?
    public var sectionScrollPosition: PublishedStateOrBinding<Section.ID?>?
    public var itemScrollPosition: PublishedStateOrBinding<Items.Element.ID?>?

    private struct ScrollPosition: Equatable {
        var section: Section.ID?
        var item: Items.Element.ID?
    }
    private var lastScrollPosition: ScrollPosition?
    private var isUpdatingScrollPosition = false
    private var scrollPositionObserver: AnyCancellable?
    private var isReadyForDisplay = false

    public private(set) var isUpdating: Bool = false
    private var updates: UInt = 0

    private var deferredInvalidationContext: UICollectionViewLayoutInvalidationContext?

    // Defaults
    private var cellRegistration: UICollectionView.CellRegistration<Layout.UICollectionViewCellType, ID>!
    private var supplementaryViewRegistration = [String: UICollectionView.SupplementaryRegistration<Layout.UICollectionViewSupplementaryViewType>]()

    public init(
        sections: [CollectionViewSection<Section, Items>],
        layout: Layout,
        layoutOptions: CollectionViewLayoutOptions
    ) {
        self.layout = layout
        self.sections = sections
        self.layoutOptions = layoutOptions
        super.init()
    }

    public func item(for indexPath: IndexPath) -> Items.Element {
        let section = sections[indexPath.section]
        let index = section.items.index(section.items.startIndex, offsetBy: indexPath.item)
        let value = section.items[index]
        return value
    }

    public func indexPath(for id: Items.Element.ID) -> IndexPath? {
        dataSource.indexPath(for: id)
    }

    open func dequeueReusableCell(
        collectionView: Layout.UICollectionViewType,
        indexPath: IndexPath,
        id: ID
    ) -> Layout.UICollectionViewCellType? {
        return collectionView.dequeueConfiguredReusableCell(
            using: cellRegistration,
            for: indexPath,
            item: id
        )
    }

    open func configureCell(
        _ cell: Layout.UICollectionViewCellType,
        indexPath: IndexPath,
        item: Items.Element
    ) {
        layout.updateUICollectionViewCell(
            collectionView,
            cell: cell,
            indexPath: indexPath,
            context: context
        )

        let isDisabled = canSelect?(indexPath, item) == .disabled
        cell.isUserInteractionEnabled = !isDisabled
    }

    open func dequeueReusableSupplementaryView(
        collectionView: Layout.UICollectionViewType,
        kind: String,
        indexPath: IndexPath
    ) -> Layout.UICollectionViewSupplementaryViewType? {
        guard let registration = supplementaryViewRegistration[kind] else { return nil }
        return collectionView.dequeueConfiguredReusableSupplementary(
            using: registration,
            for: indexPath
        )
    }

    open func configureSupplementaryView(
        _ supplementaryView: Layout.UICollectionViewSupplementaryViewType,
        kind: String,
        indexPath: IndexPath
    ) {
        layout.updateUICollectionViewSupplementaryView(
            collectionView,
            supplementaryView: supplementaryView,
            kind: kind,
            indexPath: indexPath,
            context: context
        )
    }

    open func configure(to collectionView: Layout.UICollectionViewType) {
        cellRegistration = UICollectionView.CellRegistration<
            Layout.UICollectionViewCellType, ID
        > { [unowned self] cellView, indexPath, id in
            configureCell(
                cellView,
                indexPath: indexPath,
                item: item(for: indexPath)
            )
        }

        for supplementaryView in layoutOptions.supplementaryViews {
            let kind = supplementaryView.kind
            supplementaryViewRegistration[kind] = UICollectionView.SupplementaryRegistration<Layout.UICollectionViewSupplementaryViewType>(
                elementKind: kind
            ) { [unowned self] supplementaryView, kind, indexPath in
                configureSupplementaryView(
                    supplementaryView,
                    kind: kind,
                    indexPath: indexPath
                )
            }
        }

        let dataSource = UICollectionViewDiffableDataSource<Section.ID, ID>(
            collectionView: collectionView
        ) { [unowned self] (collectionView: UICollectionView, indexPath: IndexPath, item: ID) -> Layout.UICollectionViewCellType? in
            guard let cell = dequeueReusableCell(
                collectionView: collectionView as! Layout.UICollectionViewType,
                indexPath: indexPath,
                id: item
            ) else {
                return nil
            }
            return cell
        }
        dataSource.supplementaryViewProvider = { [unowned self] (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            guard let supplementaryView = dequeueReusableSupplementaryView(
                collectionView: collectionView as! Layout.UICollectionViewType,
                kind: kind,
                indexPath: indexPath
            ) else {
                return nil
            }
            return supplementaryView
        }
        if #available(iOS 15.0, *) {
            dataSource.reorderingHandlers.canReorderItem = { [unowned self] id in
                guard let indexPath = self.indexPath(for: id) else { return false }
                return canMoveItem(at: indexPath)
            }
            dataSource.reorderingHandlers.willReorder = { [unowned self] transaction in
                willReorder(transaction: transaction)
            }
            dataSource.reorderingHandlers.didReorder = { [unowned self] transaction in
                didReorder(transaction: transaction)
            }
        }
        collectionView.dragInteractionEnabled = onReorder != nil
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.prefetchDataSource = self
        collectionView.delegate = self
        self.collectionView = collectionView
        self.dataSource = dataSource
        configureRefreshControl()
    }

    open func configureRefreshControl() {
        if onRefresh == nil {
            refreshTask?.cancel()
            collectionView.refreshControl = nil
        } else if collectionView.refreshControl == nil {
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action: #selector(refreshControlDidChange), for: .valueChanged)
            collectionView.refreshControl = refreshControl
        }
    }

    @objc
    private func refreshControlDidChange() {
        guard let onRefresh, let refreshControl = collectionView.refreshControl else {
            return
        }
        refreshTask?.cancel()
        refreshTask = Task(priority: .userInitiated) {
            await onRefresh()
            guard !Task.isCancelled else { return }
            await MainActor.run {
                refreshControl.endRefreshing()
            }
        }
    }

    private func configureScrollPositionObserver() {
        let sectionPublisher = sectionScrollPosition?.publisher?
            .compactMap { $0 }
        let itemPublisher = itemScrollPosition?.publisher?
            .compactMap { $0 }
        if let sectionPublisher, let itemPublisher {
            scrollPositionObserver = Publishers.CombineLatest(sectionPublisher, itemPublisher)
                .debounce(for: 0, scheduler: DispatchQueue.main)
                .sink { [unowned self] section, item in
                    self.scrollPositionDidChange(section: section, item: item)
                }
        } else if let sectionPublisher {
            scrollPositionObserver = sectionPublisher
                .debounce(for: 0, scheduler: DispatchQueue.main)
                .sink { [unowned self] section in
                    self.scrollPositionDidChange(section: section)
                }
        } else if let itemPublisher {
            scrollPositionObserver = itemPublisher
                .debounce(for: 0, scheduler: DispatchQueue.main)
                .sink { [unowned self] item in
                    self.scrollPositionDidChange(item: item)
                }
        } else {
            scrollPositionObserver = nil
        }
    }

    private func onAppear(for indexPath: IndexPath) {
        guard let onItemWillAppear else { return }
        let section = sections[indexPath.section]
        let item = item(for: indexPath)
        onItemWillAppear(indexPath, section, item)
    }

    func update(
        layout: Layout,
        layoutOptions: CollectionViewLayoutOptions,
        sections: [CollectionViewSection<Section, Items>]
    ) {
        didStartUpdate()
        configureScrollPositionObserver()
        let layoutDidChange = self.layout.configuration != layout.configuration
        self.layout = layout
        self.layoutOptions = layoutOptions

        let changes: (Set<ID>) -> Void = { [unowned self] updated in
            layout.updateUICollectionView(collectionView, context: context)
            if let collectionViewLayout = collectionView.collectionViewLayout as? Layout.UICollectionViewLayoutType {
                layout.updateUICollectionViewLayout(
                    collectionViewLayout,
                    context: context,
                    options: layoutOptions
                )
            }
            if layoutDidChange {
                collectionView.collectionViewLayout.invalidateLayout()
                syncScrollPosition(scrollViewDidScroll: false)
            } else {
                let layoutInvalidationContext = self.updateVisibleViews(updated: updated)
                let didScroll = syncScrollPosition(scrollViewDidScroll: false)
                if layoutInvalidationContext.invalidatedItemIndexPaths?.isEmpty == false || layoutInvalidationContext.invalidatedSupplementaryIndexPaths?.isEmpty == false {
                    if didScroll || isUpdatingScrollPosition || collectionView.isTracking || collectionView.isDecelerating {
                        deferredInvalidationContext = layoutInvalidationContext
                    } else {
                        collectionView.collectionViewLayout.invalidateLayout(with: layoutInvalidationContext)
                    }
                }
            }
        }

        let animation = isUpdatingScrollPosition ? nil : context.transaction.animation
        updateDataSource(
            sections: sections,
            animated: animation != nil,
            completion: { updated in
                if animation != nil {
                    self.collectionView.performBatchUpdates {
                        changes(updated)
                    } completion: { _ in
                        self.didFinishUpdate()
                    }
                } else {
                    UIView.performWithoutAnimation {
                        changes(updated)
                        self.didFinishUpdate()
                    }
                }
            }
        )
    }

    open func didStartUpdate() {
        isUpdating = true
        deferredInvalidationContext = nil
    }

    open func didFinishUpdate() {
        context.transaction = Transaction()
        isReadyForDisplay = collectionView.frame != .zero
        if !isUpdatingScrollPosition {
            syncScrollPosition(scrollViewDidScroll: false)
        }
        isUpdating = false
        updates = updates &+ 1
    }

    private func updateDataSource(
        sections: [CollectionViewSection<Section, Items>],
        animated: Bool,
        completion: ((Set<ID>) -> Void)? = nil
    ) {
        var snapshot = NSDiffableDataSourceSnapshot<Section.ID, ID>()
        if !sections.isEmpty {
            snapshot.appendSections(sections.map({ $0.section.id }))
            for section in sections {
                let ids = section.items.map({ $0.id })
                snapshot.appendItems(ids, toSection: section.section.id)
            }
        }
        var updated = Set<ID>()

        let indexPathsForVisibleItems = collectionView.indexPathsForVisibleItems
        for indexPath in indexPathsForVisibleItems {
            guard
                self.sections.count > indexPath.section,
                sections.count > indexPath.section
            else {
                continue
            }
            guard
                self.sections[indexPath.section].items.count > indexPath.item,
                sections[indexPath.section].items.count > indexPath.item
            else {
                continue
            }
            let index = sections[indexPath.section].items.index(
                sections[indexPath.section].items.startIndex,
                offsetBy: indexPath.item
            )
            let id = sections[indexPath.section].items[index].id
            updated.insert(id)
        }

        if #available(iOS 15.0, *), !updated.isEmpty {
            snapshot.reconfigureItems(Array(updated))
            updated = []
        }

        self.sections = sections
        // Preserve content offset during snapshot update to prevent jumpy glitch
        let isRefreshing = collectionView.refreshControl?.isRefreshing ?? false
        let contentOffset = collectionView.contentOffset
        dataSource.applySnapshot(snapshot, animated: animated) {
            completion?(updated)
        }
        if isRefreshing, collectionView.isDragging {
            collectionView.setContentOffset(contentOffset, animated: false)
        }
    }

    @discardableResult
    private func updateVisibleViews(updated: Set<ID>) -> UICollectionViewLayoutInvalidationContext {
        let context = UICollectionViewLayoutInvalidationContext()
        if !updated.isEmpty {
            for indexPath in collectionView.indexPathsForVisibleItems {
                if let cellView = collectionView.cellForItem(at: indexPath) as? Layout.UICollectionViewCellType {
                    let section = sections[indexPath.section]
                    let index = section.items.index(section.items.startIndex, offsetBy: indexPath.item)
                    let item = section.items[index]
                    if updated.contains(item.id) {
                        configureCell(cellView, indexPath: indexPath, item: item)
                        context.invalidateItems(at: [indexPath])
                    }
                }
            }
        }
        for supplementaryView in layoutOptions.supplementaryViews {
            let kind = supplementaryView.kind
            for indexPath in collectionView.indexPathsForVisibleSupplementaryElements(ofKind: kind) {
                guard let supplementaryView = collectionView.supplementaryView(forElementKind: kind, at: indexPath) as? Layout.UICollectionViewSupplementaryViewType else {
                    continue
                }
                configureSupplementaryView(supplementaryView, kind: kind, indexPath: indexPath)
                context.invalidateSupplementaryElements(ofKind: kind, at: [indexPath])
            }
        }
        return context
    }

    private func scrollPositionDidChange(
        section: Section.ID? = nil,
        item: Items.Element.ID? = nil
    ) {
        guard !isUpdating, !(isUpdatingScrollPosition && collectionView.isDragging) else { return }
        syncScrollPosition(
            scrollViewDidScroll: false,
            scrollPositionDidChange: true,
            section: section,
            item: item
        )
    }

    private func syncScrollViewDidScroll() {
        if !isUpdating, !isUpdatingScrollPosition, !collectionView.isBouncing {
            isUpdatingScrollPosition = true
            let didSync = syncScrollPosition(scrollViewDidScroll: true)
            if didSync {
                isReadyForDisplay = true
            }
            isUpdatingScrollPosition = false
        }
        if isReadyForDisplay, !isUpdating || isUpdatingScrollPosition, let onScroll {
            let contentOffset = collectionView.contentOffset
            let edgeInsets = EdgeInsets(
                edgeInsets: collectionView.adjustedContentInset,
                layoutDirection: collectionView.traitCollection.layoutDirection
            )
            if updates > 1 {
                onScroll(edgeInsets, contentOffset)
            } else {
                withCATransaction {
                    onScroll(edgeInsets, contentOffset)
                }
            }
        }
    }

    @discardableResult
    private func syncScrollPosition(
        scrollViewDidScroll: Bool = false,
        scrollPositionDidChange: Bool = false,
        section: Section.ID? = nil,
        item: Items.Element.ID? = nil
    ) -> Bool {
        guard sectionScrollPosition != nil || itemScrollPosition != nil, (isReadyForDisplay || isUpdatingScrollPosition) else {
            return false
        }
        var position: ScrollPosition?
        let shouldSyncToCurrentScrollPosition = scrollViewDidScroll && lastScrollPosition != nil
        if shouldSyncToCurrentScrollPosition {
            position = currentScrollPosition()
        } else {
            let section = section ?? sectionScrollPosition?.wrappedValue
            let item = item ?? itemScrollPosition?.wrappedValue
            position = ScrollPosition(section: section, item: item)
        }
        if sectionScrollPosition == nil {
            position?.section = lastScrollPosition?.section
        }
        if itemScrollPosition == nil {
            position?.item = lastScrollPosition?.item
        }
        if sectionScrollPosition == nil, lastScrollPosition?.item == position?.item {
            return false
        }
        if itemScrollPosition == nil, lastScrollPosition?.section == position?.section {
            return false
        }
        guard var position, position != lastScrollPosition else { return false }
        var indexPath: IndexPath?
        if !shouldSyncToCurrentScrollPosition {
            if itemScrollPosition != nil, position.item != lastScrollPosition?.item, let itemId = position.item {
                indexPath = dataSource.indexPath(for: itemId)
            }
            if sectionScrollPosition != nil, let sectionId = position.section, lastScrollPosition?.section != sectionId {
                let section: Int?
                if #available(iOS 15.0, *) {
                    section = dataSource.index(for: sectionId)
                } else {
                    section = sections.firstIndex(where: { $0.id == sectionId })
                }
                if let section, indexPath?.section != section {
                    indexPath = IndexPath(item: 0, section: section)
                    position.item = sections[section].items.first?.id
                }
            }
            if indexPath == nil, let previousPosition = lastScrollPosition ?? currentScrollPosition() {
                position = previousPosition
            }
        }

        var didScroll = false
        let transaction = context.transaction
        if isUpdating || scrollPositionDidChange || lastScrollPosition == nil, !shouldSyncToCurrentScrollPosition, let indexPath {
            let wasUpdatingScrollPosition = isUpdatingScrollPosition
            isUpdatingScrollPosition = true
            if wasUpdatingScrollPosition {
                if #available(iOS 17.4, *), collectionView.isScrollAnimating {
                    collectionView.stopScrollingAndZooming()
                } else {
                    collectionView.setContentOffset(collectionView.contentOffset, animated: false)
                }
            }
            if !isReadyForDisplay {
                collectionView.layoutIfNeeded()
            }
            let isAnimated = transaction.isAnimated || scrollPositionDidChange
            collectionView.scrollToItem(
                at: indexPath,
                at: collectionView.axis.contains(.vertical) ? .top : .left,
                animated: transaction.isAnimated || scrollPositionDidChange
            )
            if !isAnimated {
                isUpdatingScrollPosition = false
            }
            didScroll = true
        }
        if !(isUpdating || scrollPositionDidChange) || indexPath == nil || lastScrollPosition != position {
            if lastScrollPosition != nil {
                withTransaction(context.transaction) {
                    if section != position.section {
                        sectionScrollPosition?.wrappedValue = position.section
                    }
                    if item != position.item {
                        itemScrollPosition?.wrappedValue = position.item
                    }
                }
            }
            lastScrollPosition = position
        }
        return didScroll
    }

    private func currentIndexPath() -> IndexPath? {
        let point = CGPoint(
            x: max(0, collectionView.contentOffset.x + collectionView.adjustedContentInset.left),
            y: max(0, collectionView.contentOffset.y + collectionView.adjustedContentInset.top)
        )
        let indexPath = collectionView.indexPath(at: point)
        return indexPath
    }

    private func currentScrollPosition() -> ScrollPosition? {
        guard let indexPath = currentIndexPath() else {
            return nil
        }
        return ScrollPosition(
            section: sections[indexPath.section].id,
            item: sections[indexPath.section].isEmpty ? nil : item(for: indexPath).id
        )
    }

    // MARK: - Drag and Drop Reordering

    open func canMoveItem(at indexPath: IndexPath) -> Bool {
        return true
    }

    open func willReorder(transaction: NSDiffableDataSourceTransaction<Section.ID, ID>) {

    }

    open func didReorder(transaction: NSDiffableDataSourceTransaction<Section.ID, ID>) {
        guard let onReorder else { return }

        var indices = IndexSet()
        var fromSection: Int?
        var toIndex: IndexPath?

        for change in transaction.difference.inferringMoves() {
            switch change {
            case .insert(let offset, let id, let associatedWith):
                if let sectionId = transaction.finalSnapshot.sectionIdentifier(containingItem: id),
                    let section = transaction.finalSnapshot.indexOfSection(sectionId)
                {
                    let item = offset + (associatedWith.map({ $0 < offset ? 1 : 0 }) ?? 0)
                    toIndex = IndexPath(item: item, section: section)
                }
            case .remove(let offset, let id, _):
                fromSection = transaction.initialSnapshot.sectionIdentifier(containingItem: id)
                    .flatMap { transaction.initialSnapshot.indexOfSection($0) }
                indices.insert(offset)
            }
        }

        guard !indices.isEmpty, let fromSection, let toIndex else { return }
        onReorder((fromSection, indices), (toIndex.section, toIndex.item))
    }

    // MARK: - UICollectionViewDataSourcePrefetching

    open func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        guard let dataPrefetcher else { return }
        let items = indexPaths.map { item(for: $0) }
        dataPrefetcher.startPrefetching(items: items)
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        guard let dataPrefetcher else { return }
        let items = indexPaths.map { item(for: $0) }
        dataPrefetcher.cancelPrefetching(items: items)
    }

    // MARK: - UICollectionViewDragDelegate

    open func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: any UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        return []
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        dragPreviewParametersForItemAt indexPath: IndexPath
    ) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        let parameters = UIDragPreviewParameters()
        parameters.visiblePath = UIBezierPath(rect: cell.bounds)
        return parameters
    }

    // MARK: - UICollectionViewDropDelegate

    open func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: any UICollectionViewDropCoordinator
    ) {
        // Handled by UICollectionViewDiffableDataSource automatically
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        dropPreviewParametersForItemAt indexPath: IndexPath
    ) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        let parameters = UIDragPreviewParameters()
        parameters.visiblePath = UIBezierPath(rect: cell.bounds)
        return parameters
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: any UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        if session.allowsMoveOperation, collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(
                operation: .move,
                intent: .insertAtDestinationIndexPath
            )
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }

    // MARK: - UICollectionViewDelegate

    open func collectionView(
        _ collectionView: UICollectionView,
        shouldHighlightItemAt indexPath: IndexPath
    ) -> Bool {
        if let availability = canSelect?(indexPath, item(for: indexPath)) {
            return availability == .available
        } else {
            return onSelect != nil
        }
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        didHighlightItemAt indexPath: IndexPath
    ) {}

    open func collectionView(
        _ collectionView: UICollectionView,
        didUnhighlightItemAt indexPath: IndexPath
    ) {}

    open func collectionView(
        _ collectionView: UICollectionView,
        shouldSelectItemAt indexPath: IndexPath
    ) -> Bool {
        return false
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {}

    open func collectionView(
        _ collectionView: UICollectionView,
        didDeselectItemAt indexPath: IndexPath
    ) {}

    open func collectionView(
        _ collectionView: UICollectionView,
        shouldDeselectItemAt indexPath: IndexPath
    ) -> Bool {
        return true
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        canPerformPrimaryActionForItemAt indexPath: IndexPath
    ) -> Bool {
        if let availability = canSelect?(indexPath, item(for: indexPath)) {
            return availability == .available
        } else {
            return onSelect != nil
        }
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        performPrimaryActionForItemAt indexPath: IndexPath
    ) {
        onSelect?(indexPath, item(for: indexPath))
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
    ) -> Bool {
        return false
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        didBeginMultipleSelectionInteractionAt indexPath: IndexPath
    ) {}

    open func collectionViewDidEndMultipleSelectionInteraction(
        _ collectionView: UICollectionView
    ) {}

    open func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        return nil
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        willDisplayContextMenu configuration: UIContextMenuConfiguration,
        animator: (any UIContextMenuInteractionAnimating)?
    ) {}

    open func collectionView(
        _ collectionView: UICollectionView,
        willEndContextMenuInteraction configuration: UIContextMenuConfiguration,
        animator: (any UIContextMenuInteractionAnimating)?
    ) {}

    open func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfiguration configuration: UIContextMenuConfiguration,
        dismissalPreviewForItemAt indexPath: IndexPath
    ) -> UITargetedPreview? {
        return nil
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfiguration configuration: UIContextMenuConfiguration,
        highlightPreviewForItemAt indexPath: IndexPath
    ) -> UITargetedPreview? {
        return nil
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
        animator: any UIContextMenuInteractionCommitAnimating
    ) {}

    open func collectionView(
        _ collectionView: UICollectionView,
        canFocusItemAt indexPath: IndexPath
    ) -> Bool {
        return true
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        selectionFollowsFocusForItemAt indexPath: IndexPath
    ) -> Bool {
        return false
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext
    ) -> Bool {
        return false
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        didUpdateFocusIn context: UICollectionViewFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {}

    open func collectionView(
        _ collectionView: UICollectionView,
        shouldSpringLoadItemAt indexPath: IndexPath,
        with context: UISpringLoadedInteractionContext
    ) -> Bool {
        return false
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        onAppear(for: indexPath)
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {}

    open func collectionView(
        _ collectionView: UICollectionView,
        willDisplaySupplementaryView view: UICollectionReusableView,
        forElementKind elementKind: String,
        at indexPath: IndexPath
    ) {}

    open func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplayingSupplementaryView view: UICollectionReusableView,
        forElementOfKind elementKind: String,
        at indexPath: IndexPath
    ) {}

    open func collectionView(
        _ collectionView: UICollectionView,
        canEditItemAt indexPath: IndexPath
    ) -> Bool {
        return false
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        transitionLayoutForOldLayout fromLayout: UICollectionViewLayout,
        newLayout toLayout: UICollectionViewLayout
    ) -> UICollectionViewTransitionLayout {
        return UICollectionViewTransitionLayout(
            currentLayout: fromLayout,
            nextLayout: toLayout
        )
    }

    // MARK: - UIScrollViewDelegate

    open func scrollViewDidScroll(
        _ scrollView: UIScrollView
    ) {
        syncScrollViewDidScroll()
    }

    open func scrollViewDidZoom(_ scrollView: UIScrollView) {}

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {}

    open func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {}

    open func scrollViewDidEndDragging(
        _ scrollView: UIScrollView,
        willDecelerate decelerate: Bool
    ) {
        if !decelerate, !isUpdating {
            isUpdatingScrollPosition = false
        }
    }

    open func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {}

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !isUpdating {
            isUpdatingScrollPosition = false
        }
        if let context = deferredInvalidationContext {
            deferredInvalidationContext = nil
            collectionView.collectionViewLayout.invalidateLayout(with: context)
        }
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isUpdatingScrollPosition = false
        if let context = deferredInvalidationContext {
            deferredInvalidationContext = nil
            collectionView.collectionViewLayout.invalidateLayout(with: context)
        }
    }

    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }

    open func scrollViewWillBeginZooming(
        _ scrollView: UIScrollView,
        with view: UIView?
    ) {}

    open func scrollViewDidEndZooming(
        _ scrollView: UIScrollView,
        with view: UIView?,
        atScale scale: CGFloat
    ) {}

    open func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return true
    }

    open func scrollViewDidScrollToTop(_ scrollView: UIScrollView) { }

    open func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {

    }
}

extension UICollectionViewDiffableDataSource {
    func applySnapshot(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        if #available(iOS 15.0, *) {
            apply(
                snapshot,
                animatingDifferences: animated,
                completion: completion
            )
        } else {
            if animated {
                apply(
                    snapshot,
                    animatingDifferences: true,
                    completion: completion
                )
            } else {
                UIView.performWithoutAnimation {
                    self.apply(
                        snapshot,
                        animatingDifferences: true,
                        completion: completion
                    )
                }
            }
        }
    }
}

extension UICollectionView {

    var isBouncing: Bool {
        guard bounces, contentSize != .zero else { return false }

        let offset = contentOffset
        let inset = adjustedContentInset
        let minY = -inset.top
        let maxY = contentSize.height - bounds.height + inset.bottom
        let minX = -inset.left
        let maxX = contentSize.width - bounds.width + inset.right
        let isVerticalBounce = offset.y <= (minY + 0.1) || (offset.y >= maxY - 0.1)
        let isHorizontalBounce = offset.x <= (minX + 0.1) || (offset.x >= maxX - 0.1)
        switch axis {
        case .vertical:
            return isVerticalBounce
        case .horizontal:
            return isHorizontalBounce
        default:
            return isVerticalBounce || isHorizontalBounce
        }
    }

    var axis: Axis.Set {
        if let layout = collectionViewLayout as? UICollectionViewCompositionalLayout {
            switch layout.configuration.scrollDirection {
            case .vertical:
                return .vertical
            case .horizontal:
                return .horizontal
            @unknown default:
                return []
            }
        }

        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            switch layout.scrollDirection {
            case .vertical:
                return .vertical
            case .horizontal:
                return .horizontal
            @unknown default:
                return []
            }
        }

        var axis: Axis.Set = []
        if contentSize.height > bounds.height {
            axis.insert(.vertical)
        }
        if contentSize.width > bounds.width {
            axis.insert(.horizontal)
        }
        return axis
    }

    func indexPath(
        at point: CGPoint,
        size: CGSize = CGSize(width: 1, height: 1),
        includesSupplementaryViews: Bool = true
    ) -> IndexPath? {
        guard
            let layoutAttributes = collectionViewLayout.layoutAttributesForElements(
                in: CGRect(origin: point, size: size)
            )
        else {
            return nil
        }
        var supplementaryViewIndexPath: IndexPath?
        if includesSupplementaryViews {
            for attributes in layoutAttributes {
                if attributes.representedElementCategory == .supplementaryView,
                    attributes.frame.contains(point),
                    attributes.alpha > 0,
                    !attributes.isHidden
                {
                    let axis = axis
                    var point = point
                    if axis.contains(.horizontal), (attributes.frame.minX - point.x) > -1e-5 {
                        point.x += attributes.frame.width
                    }
                    if axis.contains(.vertical), (attributes.frame.minY - point.y) > -1e-5 {
                        point.y += attributes.frame.height
                    }
                    if let indexPath = indexPath(at: point, includesSupplementaryViews: false),
                        indexPath.section == attributes.indexPath.section
                    {
                        return indexPath
                    }
                    supplementaryViewIndexPath = attributes.indexPath
                    break
                }
            }
        }
        for attributes in layoutAttributes {
            if attributes.representedElementCategory == .cell,
                attributes.frame.contains(point),
                attributes.alpha > 0,
                !attributes.isHidden
            {
                return attributes.indexPath
            }
        }
        if let supplementaryViewIndexPath {
            return supplementaryViewIndexPath
        }
        if includesSupplementaryViews {
            return layoutAttributes.first?.indexPath
        }
        return nil
    }
}

#endif

// MARK: - Previews

#if os(iOS)

@available(iOS 15.0, *)
struct CollectionViewCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        PreviewA()
        PreviewB()
        PreviewC()
    }

    struct PreviewA: View {

        @StateObject var viewModel = ListViewModel()

        var body: some View {
            ListView(
                sections: [
                    CollectionViewSection(items: viewModel.items, section: 0)
                ],
                proxy: viewModel.proxy
            )
            .ignoresSafeArea()
            .overlay(alignment: .bottomTrailing) {
                VStack {
                    if let selected = viewModel.selected {
                        Text(selected.value, format: .number)
                            .frame(width: 44, height: 44)
                            .background(.ultraThickMaterial)
                    }

                    Button {
                        withAnimation {
                            viewModel.items[0].value += 1
                        }
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 44, height: 44)
                            .background(.ultraThickMaterial)
                    }

                    Button {
                        withAnimation {
                            viewModel.items.append(ListItem(value: viewModel.items.count))
                        }
                    } label: {
                        Image(systemName: "rectangle.stack.badge.plus")
                            .frame(width: 44, height: 44)
                            .background(.ultraThickMaterial)
                    }

                    Button {
                        withAnimation {
                            _ = viewModel.items.popLast()
                        }
                    } label: {
                        Image(systemName: "rectangle.stack.badge.minus")
                            .frame(width: 44, height: 44)
                            .background(.ultraThickMaterial)
                    }
                    .disabled(viewModel.items.isEmpty)

                    Button {
                        withAnimation {
                            viewModel.items.shuffle()
                        }
                    } label: {
                        Image(systemName: "shuffle")
                            .frame(width: 44, height: 44)
                            .background(.ultraThickMaterial)
                    }

                    Button {
                        viewModel.scrollToBottom()
                    } label: {
                        Image(systemName: "arrow.down")
                            .frame(width: 44, height: 44)
                            .background(.ultraThickMaterial)
                    }
                }
                .buttonStyle(.plain)
                .padding([.bottom, .trailing])
            }
        }
    }

    class ListViewModel: ObservableObject, ListCoordinatorProxy.OutputDelegate {
        @Published var items: [ListItem] = (0..<3).map { ListItem(value: $0) }
        @Published var selected: ListItem?

        let proxy = ListCoordinatorProxy()

        init() {
            proxy.outputDelegate = self
        }

        @MainActor
        func scrollToBottom() {
            proxy.inputDelegate?.scrollToBottom()
        }

        // MARK: - ListCoordinatorProxy.OutputDelegate

        func didSelectListItem(_ item: CollectionViewCoordinator_Previews.ListItem) {
            selected = item
        }
    }

    struct ListItem: Equatable, Identifiable {
        var id = UUID()
        var value: Int
    }

    struct ListView: CollectionViewRepresentable {

        var sections: [CollectionViewSection<CollectionViewSectionIndex, [ListItem]>]
        var layout = ListLayout()
        var proxy: ListCoordinatorProxy

        var layoutOptions: CollectionViewLayoutOptions {
            CollectionViewLayoutOptions(supplementaryViews: [])
        }

        func makeCoordinator() -> ListCoordinator {
            let coordinator = ListCoordinator(
                sections: sections,
                layout: layout,
                layoutOptions: layoutOptions
            )
            coordinator.configure(to: proxy)
            return coordinator
        }

        func updateCoordinator(_ coordinator: Coordinator) { }
    }

    struct ListLayout: CollectionViewLayout {

        typealias UICollectionViewCellType = UICollectionViewListCell

        func makeUICollectionViewLayout(
            context: Context,
            options: CollectionViewLayoutOptions
        ) -> UICollectionViewCompositionalLayout {
            let configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            let layout = UICollectionViewCompositionalLayout.list(using: configuration)
            return layout
        }

        func makeUICollectionView(
            context: Context,
            options: CollectionViewLayoutOptions
        ) -> UICollectionView {
            let layout = makeUICollectionViewLayout(context: context, options: options)
            let uiCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            return uiCollectionView
        }

        func updateUICollectionView(
            _ collectionView: UICollectionView,
            context: Context
        ) { }
    }

    class ListCoordinatorProxy: NSObject {
        @MainActor
        protocol InputDelegate: AnyObject {
            func scrollToBottom()
        }

        protocol OutputDelegate: AnyObject {
            func didSelectListItem(_ item: ListItem)
        }

        // To ListCoordinator
        weak var inputDelegate: InputDelegate?

        // From ListCoordinator
        weak var outputDelegate: OutputDelegate?
    }

    class ListCoordinator: CollectionViewCoordinator<
        ListLayout, CollectionViewSectionIndex, Array<ListItem>
    >, ListCoordinatorProxy.InputDelegate {

        weak var proxy: ListCoordinatorProxy?

        func configure(to proxy: ListCoordinatorProxy) {
            self.proxy = proxy
            proxy.inputDelegate = self
            onSelect = { indexPath, item in
                proxy.outputDelegate?.didSelectListItem(item)
            }
        }

        override func configureCell(
            _ cell: UICollectionViewListCell,
            indexPath: IndexPath,
            item: ListItem
        ) {
            var content = cell.defaultContentConfiguration()
            content.text = item.id.uuidString
            content.secondaryText = item.value.description
            cell.contentConfiguration = content
        }

        // MARK: - ListCoordinatorProxy.InputDelegate

        func scrollToBottom() {
            let section = collectionView.numberOfSections - 1
            if section >= 0 {
                let item = collectionView.numberOfItems(inSection: section) - 1
                if item >= 0 {
                    let indexPath = IndexPath(item: item, section: section)
                    collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
            }
        }
    }

    struct PreviewB: View {
        struct Item: Identifiable, Equatable {
            var id = UUID().uuidString
            var value = 0
        }

        @State var items: [Item] = (0..<5).map { Item(value: $0) }

        var body: some View {
            CollectionView(
                .compositional(spacing: 4),
                items: items
            ) { indexPath, section, item in
                Text(item.value.description)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
            }
            .onReorder { from, to in
                items.move(
                    fromOffsets: from.indices,
                    toOffset: to.destination
                )
            }
        }
    }

    struct PreviewC: View {

        var body: some View {
            CollectionView(
                .compositional(
                    axis: .vertical,
                    spacing: 12,
                    pinnedViews: [.header]
                ),
                sections: [
                    CollectionViewSection(items: Array(0..<20), id: \.self, section: 0),
                    CollectionViewSection(items: Array(20..<40), id: \.self, section: 1),
                    CollectionViewSection(items: Array(40..<60), id: \.self, section: 2),
                ]
            ) { indexPath, section, id in
                Text("Cell \(id.value)")
            } header: { _, _ in
                Header()
            } footer: { _, _ in

            }
            .ignoresSafeArea()
        }

        struct Header: View {
            var body: some View {
                Text("Header")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Material.ultraThin)
            }
        }
    }
}

#endif
