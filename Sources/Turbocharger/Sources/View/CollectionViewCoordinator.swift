//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

/// A `UICollectionViewDiffableDataSource` wrapper
@MainActor
@available(iOS 14.0, *)
open class CollectionViewCoordinator<
    Layout: CollectionViewLayout,
    Section: Equatable & Identifiable,
    Items: RandomAccessCollection
>: NSObject, UICollectionViewDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate where
    Items.Index: Hashable & Sendable,
    Items.Element: Equatable & Identifiable,
    Items.Element.ID: Sendable,
    Section.ID: Sendable
{
    public typealias ID = Items.Element.ID

    public let layoutOptions: CollectionViewLayoutOptions
    public var context: CollectionViewLayoutContext = .init(environment: .init(), transaction: .init())
    public private(set) var layout: Layout
    public private(set) var sections: [CollectionViewSection<Section, Items>]
    public private(set) var dataSource: UICollectionViewDiffableDataSource<Section.ID, ID>!
    public private(set) weak var collectionView: Layout.UICollectionViewType!

    public var onSelect: ((IndexPath, Items.Element) -> Void)?

    public var refresh: (() async -> Void)? {
        didSet {
            configureRefreshControl()
        }
    }
    private var refreshTask: Task<Void, Never>?

    public var reorder: ((_ from: (Int, IndexSet), _ to: (Int, Int)) -> Void)? {
        didSet {
            collectionView.dragInteractionEnabled = reorder != nil
            updateSeed = updateSeed &+ 1
        }
    }

    public var onScroll: ((CGPoint) -> Void)?

    private var updateSeed: UInt = 0
    private var lastUpdateSeed: UInt = 0

    // Defaults
    private var cellRegistration: UICollectionView.CellRegistration<Layout.UICollectionViewCellType, ID>!
    private var supplementaryViewRegistration = [String: UICollectionView.SupplementaryRegistration<Layout.UICollectionViewSupplementaryViewType>]()

    public init(
        sections: [CollectionViewSection<Section, Items>],
        onSelect: ((IndexPath, Items.Element) -> Void)? = nil,
        refresh: (() async -> Void)? = nil,
        reorder: ((_ from: (Int, IndexSet), _ to: (Int, Int)) -> Void)? = nil,
        layout: Layout,
        layoutOptions: CollectionViewLayoutOptions
    ) {
        self.layout = layout
        self.sections = sections
        self.onSelect = onSelect
        self.refresh = refresh
        self.reorder = reorder
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
        fatalError("\(#function) should be overridden by class \(Self.self)")
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
        fatalError("\(#function) should be overridden by class \(Self.self)")
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
            layout.updateUICollectionViewCell(
                collectionView as! Layout.UICollectionViewType,
                cell: cell,
                indexPath: indexPath,
                context: context
            )
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
            layout.updateUICollectionViewSupplementaryView(
                collectionView as! Layout.UICollectionViewType,
                supplementaryView: supplementaryView,
                kind: kind,
                indexPath: indexPath,
                context: context
            )
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
        collectionView.dragInteractionEnabled = reorder != nil
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.delegate = self
        self.collectionView = collectionView
        self.dataSource = dataSource
        configureRefreshControl()
    }

    open func configureRefreshControl() {
        if refresh == nil {
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
        guard let refresh, let refreshControl = collectionView.refreshControl else {
            return
        }
        refreshTask?.cancel()
        refreshTask = Task(priority: .userInitiated) {
            await refresh()
            guard !Task.isCancelled else { return }
            await MainActor.run {
                refreshControl.endRefreshing()
            }
        }
    }

    func update(layout: Layout) {
        self.layout = layout
        layout.updateUICollectionView(collectionView, context: context)
    }

    func update(sections: [CollectionViewSection<Section, Items>]) {
        performUpdate(sections: sections, animation: context.transaction.animation)
    }

    /// Updates the data source, you should not call this directly when using ``CollectionViewRepresentable``
    open func performUpdate(
        sections: [CollectionViewSection<Section, Items>],
        animation: Animation?,
        completion: (() -> Void)? = nil
    ) {
        let (wasEmpty, updated) = updateDataSource(
            sections: sections,
            animated: animation != nil,
            completion: completion
        )
        let hasSupplementaryViews = !layoutOptions.supplementaryViews.isEmpty
        guard (!updated.isEmpty && !wasEmpty) || hasSupplementaryViews else {
            return
        }

        if let animation {
            if #available(iOS 18.0, *) {
                UIView.animate(animation) {
                    self.updateVisibleViews(updated: updated)
                }
            } else {
                UIView.animate(
                    withDuration: animation.duration(defaultDuration: 0.35),
                    delay: animation.delay ?? 0,
                    options: [.curveEaseInOut]
                ) {
                    self.updateVisibleViews(updated: updated)
                }
            }
        } else {
            var selfSizingInvalidation: Int?
            if #available(iOS 16.0, *) {
                selfSizingInvalidation = collectionView.selfSizingInvalidation.rawValue
                collectionView.selfSizingInvalidation = .disabled
            }
            UIView.performWithoutAnimation {
                let context = updateVisibleViews(updated: updated)
                collectionView.collectionViewLayout.invalidateLayout(with: context)
            }
            if #available(iOS 16.0, *),
                let selfSizingInvalidation,
                let oldValue = UICollectionView.SelfSizingInvalidation(rawValue: selfSizingInvalidation)
            {
                withCATransaction { [weak self] in
                    self?.collectionView.selfSizingInvalidation = oldValue
                }
            }
        }
    }

    private func updateDataSource(
        sections: [CollectionViewSection<Section, Items>],
        animated: Bool,
        completion: (() -> Void)? = nil
    ) -> (Bool, Set<ID>) {
        defer { lastUpdateSeed = updateSeed }
        let oldValue = dataSource.snapshot().itemIdentifiers
        var newValue = [ID]()
        newValue.reserveCapacity(sections.reduce(into: 0) { $0 += $1.count })

        var snapshot = NSDiffableDataSourceSnapshot<Section.ID, ID>()
        if !sections.isEmpty {
            snapshot.appendSections(sections.map({ $0.section.id }))
            for section in sections {
                let ids = section.items.map({ $0.id })
                snapshot.appendItems(ids, toSection: section.section.id)
                newValue.append(contentsOf: ids)
            }
        }
        lazy var didChangeOrder = oldValue != newValue
        lazy var added = Set(newValue).subtracting(oldValue)
        lazy var removed = Set(oldValue).subtracting(newValue)
        var updated = Set<ID>()

        if !oldValue.isEmpty {
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
                if updateSeed != lastUpdateSeed {
                    updated.insert(id)
                } else if self.sections[indexPath.section].items[index].id == sections[indexPath.section].items[index].id {
                    if self.sections[indexPath.section].items[index] != sections[indexPath.section].items[index] {
                        updated.insert(id)
                    }
                }
            }
        }

        guard didChangeOrder || !added.isEmpty || !updated.isEmpty || !removed.isEmpty else {
            return (oldValue.isEmpty, updated)
        }

        if #available(iOS 15.0, *), !updated.isEmpty {
            snapshot.reconfigureItems(Array(updated))
            updated = []
        }

        self.sections = sections
        // Preserve content offset during snapshot update to prevent jumpy glitch
        let isRefreshing = collectionView.refreshControl?.isRefreshing ?? false
        let contentOffset = collectionView.contentOffset
        dataSource.applySnapshot(snapshot, animated: animated, completion: completion)
        if isRefreshing, collectionView.isDragging {
            collectionView.setContentOffset(contentOffset, animated: false)
        }
        return (oldValue.isEmpty, updated)
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

    // MARK: - Drag and Drop Reordering

    open func canMoveItem(at indexPath: IndexPath) -> Bool {
        return true
    }

    open func willReorder(transaction: NSDiffableDataSourceTransaction<Section.ID, ID>) {

    }

    open func didReorder(transaction: NSDiffableDataSourceTransaction<Section.ID, ID>) {
        guard let reorder else { return }

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

        updateSeed = updateSeed &+ 1
        reorder((fromSection, indices), (toIndex.section, toIndex.item))
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
        return onSelect != nil
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
        return onSelect != nil
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        onSelect?(indexPath, item(for: indexPath))
        collectionView.deselectItem(at: indexPath, animated: true)
    }

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
        return false
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        performPrimaryActionForItemAt indexPath: IndexPath
    ) {}

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
    ) {}

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
        onScroll?(scrollView.contentOffset)
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
    ) {}

    open func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {}

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {}

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

        func makeCoordinator() -> ListCoordinator {
            let coordinator = ListCoordinator(
                sections: sections,
                layout: layout,
                layoutOptions: .init(
                    supplementaryViews: []
                )
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
            .reorderable { from, to in
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
