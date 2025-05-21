//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

/// A collection wrapper for grouping items in a section
public struct CollectionViewSection<
    Data: RandomAccessCollection & Equatable,
    Section: Equatable
>: RandomAccessCollection, Equatable where Data.Element: Equatable & Identifiable {

    public var items: Data
    public var section: Section

    public init(items: Data, section: Section) {
        self.items = items
        self.section = section
    }

    // MARK: - RandomAccessCollection

    public typealias Index = Data.Index
    public typealias Element = Data.Element

    public var startIndex: Index {
        items.startIndex
    }

    public var endIndex: Index {
        items.endIndex
    }

    public subscript(position: Index) -> Element {
        items[position]
    }

    public func index(after i: Index) -> Index {
        items.index(after: i)
    }

    public func index(before i: Index) -> Index {
        items.index(before: i)
    }
}

/// A `UICollectionViewDiffableDataSource` wrapper
@MainActor
@available(iOS 14.0, *)
open class CollectionViewCoordinator<
    Layout: CollectionViewLayout,
    Data: RandomAccessCollection
>: NSObject where
    Data.Element: RandomAccessCollection,
    Data.Index: Hashable,
    Data.Element.Element: Equatable & Identifiable
{
    public typealias Section = Data.Index
    public typealias ID = Data.Element.Element.ID

    public let layoutOptions: CollectionViewLayoutOptions
    public var context: CollectionViewLayoutContext = .init(environment: .init(), transaction: .init())
    public private(set) var layout: Layout
    public private(set) var data: Data
    public private(set) var dataSource: UICollectionViewDiffableDataSource<Section, ID>!
    public private(set) weak var collectionView: Layout.UICollectionViewType!

    public var refresh: (() async -> Void)? {
        didSet {
            configureRefreshControl()
        }
    }
    private var refreshTask: Task<Void, Never>?

    // Defaults
    private var cellRegistration: UICollectionView.CellRegistration<Layout.UICollectionViewCellType, ID>!
    private var supplementaryViewRegistration = [String: UICollectionView.SupplementaryRegistration<Layout.UICollectionViewSupplementaryViewType>]()

    public init(
        data: Data,
        refresh: (() async -> Void)? = nil,
        layout: Layout,
        layoutOptions: CollectionViewLayoutOptions
    ) {
        self.layout = layout
        self.data = data
        self.refresh = refresh
        self.layoutOptions = layoutOptions
        super.init()
    }

    public func item(for indexPath: IndexPath) -> Data.Element.Element {
        let section = data.index(data.startIndex, offsetBy: indexPath.section)
        let item = data[section].index(data[section].startIndex, offsetBy: indexPath.item)
        let value = data[section][item]
        return value
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
        item: Data.Element.Element
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

        let dataSource = UICollectionViewDiffableDataSource<Section, ID>(
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

    func update(data: Data) {
        performUpdate(data: data, animation: context.transaction.animation)
    }

    /// Updates the data source, you should not call this directly when using ``CollectionViewRepresentable``
    open func performUpdate(
        data: Data,
        animation: Animation?,
        completion: (() -> Void)? = nil
    ) {

        let (wasEmpty, updated) = updateDataSource(data: data, animated: animation != nil, completion: completion)
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
            var selfSizingInvalidation: Any?
            if #available(iOS 16.0, *) {
                selfSizingInvalidation = collectionView.selfSizingInvalidation
                collectionView.selfSizingInvalidation = .disabled
            }
            UIView.performWithoutAnimation {
                let context = updateVisibleViews(updated: updated)
                collectionView.collectionViewLayout.invalidateLayout(with: context)
            }
            if #available(iOS 16.0, *) {
                let oldValue = selfSizingInvalidation as! UICollectionView.SelfSizingInvalidation
                withCATransaction {
                    self.collectionView.selfSizingInvalidation = oldValue
                }
            }
        }
    }

    private func updateDataSource(
        data: Data,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) -> (Bool, Set<ID>) {
        let oldValue = dataSource.snapshot().itemIdentifiers
        var newValue = [ID]()
        newValue.reserveCapacity(data.reduce(into: 0) { $0 += $1.count })

        var snapshot = NSDiffableDataSourceSnapshot<Section, ID>()
        if !data.isEmpty {
            snapshot.appendSections(Array(data.indices))
            for section in data.indices {
                let ids = data[section].map(\.id)
                snapshot.appendItems(ids, toSection: section)
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
                    self.data.count > indexPath.section,
                    data.count > indexPath.section
                else {
                    continue
                }
                let section = data.index(data.startIndex, offsetBy: indexPath.section)
                guard
                    self.data[section].count > indexPath.item,
                    data[section].count > indexPath.item
                else {
                    continue
                }
                let item = data[section].index(data[section].startIndex, offsetBy: indexPath.item)
                if self.data[section][item].id == data[section][item].id {
                    if self.data[section][item] != data[section][item] {
                        updated.insert(data[section][item].id)
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

        self.data = data
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
                    let section = data.index(data.startIndex, offsetBy: indexPath.section)
                    let item = data[section].index(data[section].startIndex, offsetBy: indexPath.item)
                    let value = data[section][item]
                    if updated.contains(value.id) {
                        configureCell(cellView, indexPath: indexPath, item: value)
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
        Preview()
    }

    struct Preview: View {

        @StateObject var viewModel = ListViewModel()

        var body: some View {
            ListView(
                data: [viewModel.items],
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

        var data: [[ListItem]]
        var layout = ListLayout()
        var proxy: ListCoordinatorProxy

        func makeCoordinator() -> ListCoordinator {
            let coordinator = ListCoordinator(
                data: data,
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
        ListLayout, Array<Array<ListItem>>
    >, UICollectionViewDelegate, ListCoordinatorProxy.InputDelegate {

        weak var proxy: ListCoordinatorProxy?

        func configure(to proxy: ListCoordinatorProxy) {
            self.proxy = proxy
            proxy.inputDelegate = self
        }

        override func configure(to collectionView: UICollectionView) {
            super.configure(to: collectionView)
            collectionView.delegate = self
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

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            collectionView.deselectItem(at: indexPath, animated: true)
            let item = item(for: indexPath)
            proxy?.outputDelegate?.didSelectListItem(item)
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
}

#endif
