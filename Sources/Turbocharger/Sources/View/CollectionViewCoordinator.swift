//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

/// A collection wrapper for grouping items in a section
public struct CollectionViewSection<
    Data: RandomAccessCollection,
    Section
>: RandomAccessCollection where Data.Element: Equatable & Identifiable {

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
        performUpdate(data: data, animated: context.transaction.isAnimated)
    }

    /// Updates the data source, you should not call this directly when using ``CollectionViewRepresentable``
    open func performUpdate(
        data: Data,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {

        let (wasEmpty, updated) = updateDataSource(data: data, animated: animated, completion: completion)
        let hasSupplementaryViews = !layoutOptions.supplementaryViews.isEmpty
        guard (!updated.isEmpty && !wasEmpty) || hasSupplementaryViews else {
            return
        }

        if animated {
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                options: [.curveEaseInOut]
            ) { [weak self] in
                self?.updateVisibleViews(updated: updated)
            }
        } else {
            var selfSizingInvalidation: Any?
            if #available(iOS 16.0, *) {
                selfSizingInvalidation = collectionView.selfSizingInvalidation
                collectionView.selfSizingInvalidation = .disabled
            }
            updateVisibleViews(updated: updated)
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
        var updated = Set<ID>()

        var snapshot = NSDiffableDataSourceSnapshot<Section, ID>()
        if !data.isEmpty {
            snapshot.appendSections(Array(data.indices))
            for section in data.indices {
                let ids = data[section].map(\.id)
                snapshot.appendItems(ids, toSection: section)
                updated.formUnion(ids)
            }
        }
        updated.formIntersection(oldValue)

        if !oldValue.isEmpty {
            for indexPath in collectionView.indexPathsForVisibleItems {
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
                    if self.data[section][item] == data[section][item] {
                        updated.remove(data[section][item].id)
                    }
                }
            }
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

    private func updateVisibleViews(updated: Set<ID>) {
        if !updated.isEmpty {
            for indexPath in collectionView.indexPathsForVisibleItems {
                if let cellView = collectionView.cellForItem(at: indexPath) as? Layout.UICollectionViewCellType {
                    let section = data.index(data.startIndex, offsetBy: indexPath.section)
                    let item = data[section].index(data[section].startIndex, offsetBy: indexPath.item)
                    let value = data[section][item]
                    if updated.contains(value.id) {
                        configureCell(cellView, indexPath: indexPath, item: value)
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
            }
        }
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

        @State var items: [ListItem] = (0..<3).map { ListItem(value: $0) }

        var body: some View {
            ListView(data: [items])
                .ignoresSafeArea()
                .overlay(alignment: .bottomTrailing) {
                    VStack {
                        Button {
                            withAnimation {
                                items[0].value += 1
                            }
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 44, height: 44)
                                .background(.ultraThickMaterial)
                        }

                        Button {
                            withAnimation {
                                items.append(ListItem(value: items.count))
                            }
                        } label: {
                            Image(systemName: "rectangle.stack.badge.plus")
                                .frame(width: 44, height: 44)
                                .background(.ultraThickMaterial)
                        }

                        Button {
                            withAnimation {
                                _ = items.popLast()
                            }
                        } label: {
                            Image(systemName: "rectangle.stack.badge.minus")
                                .frame(width: 44, height: 44)
                                .background(.ultraThickMaterial)
                        }
                        .disabled(items.isEmpty)

                        Button {
                            items.shuffle()
                        } label: {
                            Image(systemName: "shuffle")
                                .frame(width: 44, height: 44)
                                .background(.ultraThickMaterial)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding([.bottom, .trailing])
                }
        }
    }

    struct ListItem: Equatable, Identifiable {
        var id = UUID()
        var value: Int
    }

    struct ListView: CollectionViewRepresentable {

        var data: [[ListItem]]
        var layout = ListLayout()

        func makeCoordinator() -> ListCoordinator {
            ListCoordinator(
                data: data,
                layout: layout,
                layoutOptions: .init(
                    supplementaryViews: []
                )
            )
        }

        func updateCoordinator(_ coordinator: Coordinator) { }
    }

    struct ListLayout: CollectionViewLayout {

        typealias UICollectionViewCellType = UICollectionViewListCell

        func makeUICollectionView(
            context: Context,
            options: CollectionViewLayoutOptions
        ) -> UICollectionView {
            let configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            let layout = UICollectionViewCompositionalLayout.list(using: configuration)
            let uiCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            return uiCollectionView
        }

        func updateUICollectionView(
            _ collectionView: UICollectionView,
            context: Context
        ) { }
    }

    class ListCoordinator: CollectionViewCoordinator<
        ListLayout, Array<Array<ListItem>>
    >, UICollectionViewDelegate {

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
        }
    }
}

#endif
