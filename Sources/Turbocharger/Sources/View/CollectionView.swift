//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct CollectionView<
    Header: View,
    Content: View,
    Footer: View,
    Layout: CollectionViewLayout,
    Data: RandomAccessCollection
>: View where
    Data.Element: RandomAccessCollection,
    Data.Index: Hashable,
    Data.Element.Element: Identifiable
{
    var layout: Layout
    var data: Data
    var header: (Data.Index) -> Header
    var content: (Data.Element.Element) -> Content
    var footer: (Data.Index) -> Footer

    public init(
        _ layout: Layout,
        sections: Data,
        @ViewBuilder content: @escaping (Data.Element.Element) -> Content,
        @ViewBuilder header: @escaping (Data.Index) -> Header,
        @ViewBuilder footer: @escaping (Data.Index) -> Footer
    ) {
        self.layout = layout
        self.data = sections
        self.header = header
        self.content = content
        self.footer = footer
    }

    #if os(iOS)
    public var body: some View {
        CollectionViewBody(
            layout: layout,
            data: data,
            header: header,
            content: content,
            footer: footer
        )
    }
    #else
    public var body: Never {
        bodyError()
    }
    #endif
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionView {
    public init<
        Items: RandomAccessCollection
    >(
        _ layout: Layout,
        items: Items,
        @ViewBuilder content: @escaping (Items.Element) -> Content,
        @ViewBuilder header: @escaping (Data.Index) -> Header,
        @ViewBuilder footer: @escaping (Data.Index) -> Footer
    ) where Items: RandomAccessCollection, Items.Element: Identifiable, Data == Array<Items>
    {
        self.init(layout, sections: [items], content: content, header: header, footer: footer)
    }

    public init<
        Items: RandomAccessCollection
    >(
        _ layout: Layout,
        items: Items,
        @ViewBuilder content: @escaping (Items.Element) -> Content,
        @ViewBuilder header: @escaping (Data.Index) -> Header
    ) where Items: RandomAccessCollection, Items.Element: Identifiable, Data == Array<Items>, Footer == EmptyView
    {
        self.init(layout, items: items, content: content, header: header, footer: { _ in EmptyView() })
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionView {
    public init<
        Sections: RandomAccessCollection,
        ID: Hashable
    >(
        _ layout: Layout,
        sections: Sections,
        id: KeyPath<Sections.Element.Element, ID>,
        @ViewBuilder content: @escaping (Sections.Element.Element) -> Content,
        @ViewBuilder header: @escaping (Data.Index) -> Header,
        @ViewBuilder footer: @escaping (Data.Index) -> Footer
    ) where Sections.Element: RandomAccessCollection, Sections.Index: Hashable, Data == Array<Array<IdentifiableBox<Sections.Element.Element, ID>>>
    {
        let data: Data = sections.compactMap { items in
            items.compactMap { IdentifiableBox($0, id: id) }
        }
        self.init(layout, sections: data, content: { content($0.value) }, header: header, footer: footer)
    }

    public init<
        Sections: RandomAccessCollection,
        ID: Hashable
    >(
        _ layout: Layout,
        sections: Sections,
        id: KeyPath<Sections.Element.Element, ID>,
        @ViewBuilder content: @escaping (Sections.Element.Element) -> Content,
        @ViewBuilder header: @escaping (Data.Index) -> Header
    ) where Sections.Element: RandomAccessCollection, Sections.Index: Hashable, Data == Array<Array<IdentifiableBox<Sections.Element.Element, ID>>>, Footer == EmptyView
    {
        self.init(layout, sections: sections, id: id, content: content, header: header, footer: { _ in EmptyView() })
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionView where Header == EmptyView, Footer == EmptyView {
    public init<
        Items: RandomAccessCollection
    >(
        _ layout: Layout,
        items: Items,
        @ViewBuilder content: @escaping (Items.Element) -> Content
    ) where Items: RandomAccessCollection, Items.Element: Identifiable, Data == Array<Items>
    {
        self.init(layout, items: items, content: content, header: { _ in EmptyView() }, footer: { _ in EmptyView() })
    }

    public init<
        Items: RandomAccessCollection,
        ID: Hashable
    >(
        _ layout: Layout,
        items: Items,
        id: KeyPath<Items.Element, ID>,
        @ViewBuilder content: @escaping (Items.Element) -> Content
    ) where Items: RandomAccessCollection, Data == Array<Array<IdentifiableBox<Items.Element, ID>>>
    {
        self.init(layout, sections: [items], id: id, content: content, header: { _ in EmptyView() }, footer: { _ in EmptyView() })
    }

    public init<
        Views: View
    >(
        _ layout: Layout,
        @ViewBuilder views: () -> Views
    ) where
        Content == MultiViewSubviewVisitor.Subview,
        Data == Array<Array<MultiViewSubviewVisitor.Subview>>
    {
        var visitor = MultiViewSubviewVisitor()
        let content = views()
        content.visit(visitor: &visitor)
        self.init(layout, items: visitor.subviews, content: { $0 })
    }
}

#if os(iOS)

@available(iOS 14.0, *)
private struct CollectionViewBody<
    Header: View,
    Content: View,
    Footer: View,
    Layout: CollectionViewLayout,
    Data: RandomAccessCollection
>: UIViewRepresentable where
    Data.Element: RandomAccessCollection,
    Data.Index: Hashable,
    Data.Element.Element: Identifiable
{

    var layout: Layout
    var data: Data
    var header: (Data.Index) -> Header
    var content: (Data.Element.Element) -> Content
    var footer: (Data.Index) -> Footer

    func makeUIView(context: Context) -> Layout.UICollectionViewType {
        var layoutOptions = CollectionViewLayoutOptions()
        if Header.self != EmptyView.self {
            layoutOptions.update(with: .header)
        }
        if Footer.self != EmptyView.self {
            layoutOptions.update(with: .footer)
        }
        let uiView = layout.makeUICollectionView(
            context: CollectionViewLayoutContext(
                environment: context.environment,
                transaction: context.transaction
            ),
            options: layoutOptions
        )
        context.coordinator.bindDataSource(to: uiView)

        return uiView
    }

    func updateUIView(_ uiView: Layout.UICollectionViewType, context: Context) {
        context.coordinator.update(
            body: self,
            uiView: uiView,
            layout: layout,
            transaction: context.transaction
        )
        layout.updateUICollectionView(
            uiView,
            context: CollectionViewLayoutContext(
                environment: context.environment,
                transaction: context.transaction
            )
        )
    }

    func makeCoordinator() -> CollectionViewCoordinator<Header, Content, Footer, Layout, Data> {
        CollectionViewCoordinator(body: self)
    }
}

@available(iOS 14.0, *)
private class CollectionViewCoordinator<
    Header: View,
    Content: View,
    Footer: View,
    Layout: CollectionViewLayout,
    Data: RandomAccessCollection
>: NSObject where
    Data.Element: RandomAccessCollection,
    Data.Index: Hashable,
    Data.Element.Element: Identifiable
{

    typealias Section = Data.Index
    typealias Item = Data.Element.Element.ID
    typealias Body = CollectionViewBody<Header, Content, Footer, Layout, Data>

    private var body: Body
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    init(body: Body) {
        self.body = body
        super.init()
    }

    func bindDataSource(to uiView: UICollectionView) {
        let cellRegistration = UICollectionView.CellRegistration<
            UICollectionViewCell, Item
        > { [unowned self] cellView, indexPath, id in
            cellView.contentConfiguration = self.makeContent(
                indexPath: indexPath
            )
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [unowned self] headerView, _, indexPath in
            headerView.contentConfiguration = self.makeHeaderContent(
                indexPath: indexPath
            )
        }
        let footerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(
            elementKind: UICollectionView.elementKindSectionFooter
        ) { [unowned self] footerView, _, indexPath in
            footerView.contentConfiguration = self.makeFooterContent(
                indexPath: indexPath
            )
        }
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: uiView
        ) { [unowned self] (collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
            cell.automaticallyUpdatesContentConfiguration = false
            self.body.layout.updateUICollectionViewCell(
                collectionView as! Layout.UICollectionViewType,
                cell: cell,
                kind: .cell,
                indexPath: indexPath
            )
            return cell
        }
        dataSource.supplementaryViewProvider = { [unowned self] (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                let headerView = collectionView.dequeueConfiguredReusableSupplementary(
                    using: headerRegistration,
                    for: indexPath
                )
                headerView.automaticallyUpdatesContentConfiguration = false
                self.body.layout.updateUICollectionViewCell(
                    collectionView as! Layout.UICollectionViewType,
                    cell: headerView,
                    kind: .supplementary(kind),
                    indexPath: indexPath
                )
                return headerView

            case UICollectionView.elementKindSectionFooter:
                let footerView = collectionView.dequeueConfiguredReusableSupplementary(
                    using: footerRegistration,
                    for: indexPath
                )
                footerView.automaticallyUpdatesContentConfiguration = false
                self.body.layout.updateUICollectionViewCell(
                    collectionView as! Layout.UICollectionViewType,
                    cell: footerView,
                    kind: .supplementary(kind),
                    indexPath: indexPath
                )
                return footerView

            default:
                return nil
            }
        }
    }

    func update(
        body: Body,
        uiView: UICollectionView,
        layout: Layout,
        transaction: Transaction
    ) {
        self.body = body

        let updated = updateDataSource(transaction: transaction)
        guard !updated.isEmpty else {
            return
        }

        if transaction.isAnimated {
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                options: [.curveEaseInOut]
            ) {
                self.updateVisibleViews(
                    uiView,
                    updated: updated
                )
            }
        } else {
            var selfSizingInvalidation: Any?
            if #available(iOS 16.0, *) {
                selfSizingInvalidation = uiView.selfSizingInvalidation
                uiView.selfSizingInvalidation = .disabled
            }
            updateVisibleViews(
                uiView,
                updated: updated
            )
            if #available(iOS 16.0, *) {
                let oldValue = selfSizingInvalidation as! UICollectionView.SelfSizingInvalidation
                withCATransaction {
                    uiView.selfSizingInvalidation = oldValue
                }
            }
        }
    }

    private func makeContent(
        indexPath: IndexPath
    ) -> UIContentConfiguration {
        let section = body.data.index(body.data.startIndex, offsetBy: indexPath.section)
        let item = body.data[section].index(body.data[section].startIndex, offsetBy: indexPath.item)
        let value = body.data[section][item]
        return makeContent(
            value: value
        )
    }

    private func makeContent(
        value: Data.Element.Element
    ) -> UIContentConfiguration {
        makeHostingConfiguration(
            id: value.id,
            kind: .cell
        ) {
            body.content(value)
        }
    }

    private func makeHeaderContent(
        indexPath: IndexPath
    ) -> UIContentConfiguration {
        let section = body.data.index(body.data.startIndex, offsetBy: indexPath.section)
        return makeHostingConfiguration(
            id: section,
            kind: .supplementary(UICollectionView.elementKindSectionHeader)
        ) {
            body.header(section)
        }
    }

    private func makeFooterContent(
        indexPath: IndexPath
    ) -> UIContentConfiguration {
        let section = body.data.index(body.data.startIndex, offsetBy: indexPath.section)
        return makeHostingConfiguration(
            id: section,
            kind: .supplementary(UICollectionView.elementKindSectionFooter)
        ) {
            body.footer(section)
        }
    }

    private func updateDataSource(transaction: Transaction) -> Set<Item> {
        let oldValue = dataSource.snapshot().itemIdentifiers
        var updated = Set<Item>()

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Array(body.data.indices))
        for section in body.data.indices {
            let ids = body.data[section].map(\.id)
            snapshot.appendItems(ids, toSection: section)
            updated.formUnion(ids)
        }
        updated.formIntersection(oldValue)

        dataSource.applySnapshot(snapshot, animated: transaction.isAnimated)
        return updated
    }

    private func updateVisibleViews(
        _ uiView: UICollectionView,
        updated: Set<Item>
    ) {
        for indexPath in uiView.indexPathsForVisibleItems {
            if let cellView = uiView.cellForItem(at: indexPath) {
                let section = body.data.index(body.data.startIndex, offsetBy: indexPath.section)
                let item = body.data[section].index(body.data[section].startIndex, offsetBy: indexPath.item)
                let value = body.data[section][item]
                if updated.contains(value.id) {
                    cellView.contentConfiguration = self.makeContent(
                        value: value
                    )
                }
            }
        }
        for indexPath in uiView.indexPathsForVisibleSupplementaryElements(
            ofKind: UICollectionView.elementKindSectionHeader
        ) {
            let headerView = uiView.supplementaryView(
                forElementKind: UICollectionView.elementKindSectionHeader,
                at: indexPath
            ) as! UICollectionViewCell
            headerView.contentConfiguration = self.makeHeaderContent(
                indexPath: indexPath
            )
        }
        for indexPath in uiView.indexPathsForVisibleSupplementaryElements(
            ofKind: UICollectionView.elementKindSectionFooter
        ) {
            let footerView = uiView.supplementaryView(
                forElementKind: UICollectionView.elementKindSectionFooter,
                at: indexPath
            ) as! UICollectionViewCell
            footerView.contentConfiguration = self.makeFooterContent(
                indexPath: indexPath
            )
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

@available(iOS 14.0, *)
private func makeHostingConfiguration<
    ID: Hashable,
    Content: View
>(
    id: ID,
    kind: HostingConfigurationKind = .cell,
    @ViewBuilder content: () -> Content
) -> UIContentConfiguration {
    if #available(iOS 16.0, *) {
        return UIHostingConfiguration {
            content()
                .modifier(HostingConfigurationModifier(id: id))
        }
        .margins(.all, 0)
    } else {
        return HostingConfigurationBackport(kind: kind) {
            content()
                .modifier(HostingConfigurationModifier(id: id))
        }
    }
}

private struct HostingConfigurationModifier<ID: Hashable>: VersionedViewModifier {
    var id: ID

    @available(iOS 16.0, *)
    func v4Body(content: Content) -> some View {
        content
            .contentTransition(.identity)
            .transition(.identity)
            .id(id)
    }

    func v1Body(content: Content) -> some View {
        content
            .transition(.identity)
            .id(id)
    }
}

@frozen
public enum HostingConfigurationKind {
    case supplementary(String)
    case cell
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct HostingConfigurationBackport<
    Content: View
>: UIContentConfiguration {
    public var kind: HostingConfigurationKind
    public var content: Content

    public init(
        kind: HostingConfigurationKind,
        @ViewBuilder content: () -> Content
    ) {
        self.kind = kind
        self.content = content()
    }

    public func makeContentView() -> UIView & UIContentView {
        return HostingConfigurationBackportContentView(configuration: self)
    }

    public func updated(for state: UIConfigurationState) -> Self {
        return self
    }
}

@available(iOS 14.0, *)
private class HostingConfigurationBackportContentView<
    Content: View
>: HostingView<ModifiedContent<Content, SizeObserver>>, UIContentView {

    var configuration: UIContentConfiguration {
        didSet {
            let configuration = configuration as! HostingConfigurationBackport<Content>
            content.content = configuration.content
        }
    }

    init(configuration: HostingConfigurationBackport<Content>) {
        self.configuration = configuration
        super.init(content: configuration.content.modifier(SizeObserver(onChange: { _ in })))
        content.modifier.onChange = { [unowned self] newValue in
            invalidateLayout(size: newValue)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func invalidateLayout(size: CGSize) {
        guard
            let collectionViewCell = superview as? UICollectionViewCell,
            let collectionView = collectionViewCell.superview as? UICollectionView,
            size.height != frame.size.height
        else {
            return
        }

        let kind = (configuration as! HostingConfigurationBackport<Content>).kind
        let ctx = UICollectionViewLayoutInvalidationContext()
        switch kind {
        case .supplementary(let kind):
            if let indexPath = collectionView.indexPath(for: collectionViewCell) {
                ctx.invalidateSupplementaryElements(ofKind: kind, at: [indexPath])
            } else {
                let indexPaths = collectionView.indexPathsForVisibleSupplementaryElements(ofKind: kind)
                ctx.invalidateSupplementaryElements(ofKind: kind, at: indexPaths)
            }
        case .cell:
            if let indexPath = collectionView.indexPath(forSupplementaryView: collectionViewCell) {
                ctx.invalidateItems(at: [indexPath])
            }
        }
        collectionView.collectionViewLayout.invalidateLayout(with: ctx)
        invalidateIntrinsicContentSize()
    }
}

@available(iOS 14.0, *)
private struct SizeObserver: ViewModifier {
    var onChange: (CGSize) -> Void

    init(onChange: @escaping (CGSize) -> Void) {
        self.onChange = onChange
    }

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .hidden()
                        .onChange(of: proxy.size, perform: onChange)
                }
            )
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CollectionView_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        struct Item: Identifiable, Equatable {
            var id = UUID().uuidString
        }

        @State var items: [Item] = [
            Item(),
            Item(),
            Item(),
        ]

        @State var isExpanded = false

        struct ItemView: View {
            var item: Item

            @State var isExpanded = false

            var body: some View {
                VStack(spacing: 0) {
                    Text(item.id)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)

                    RoundedRectangle(cornerRadius: isExpanded ? 6 : 0)
                        .fill(Color.red)
                        .frame(height: isExpanded ? 100 : 0)
                        .opacity(isExpanded ? 1 : 0)
                }
                .padding(6)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(6)
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
            }
        }

        struct HeaderFooterView: View {
            var text: String

            @State var isExpanded = false

            var body: some View {
                VStack(alignment: .leading) {
                    HStack {
                        Text(text)
                            .font(.title3)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button("Show More") {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }
                    }

                    if isExpanded {
                        Text("More Info")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .background(Color.blue)
                .foregroundStyle(.white)
            }
        }

        var body: some View {
            CollectionView(.list, items: items) { item in
                ItemView(item: item)
            } header: { index in
                HeaderFooterView(text: "Header")
            } footer: { index in
                HeaderFooterView(text: "Footer")
            }
            .animation(.default, value: items)
            .ignoresSafeArea()
            .overlay(alignment: .bottomTrailing) {
                VStack {
                    Button {
                        withAnimation {
                            items.append(Item())
                        }
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 44, height: 44)
                            .background(.ultraThickMaterial)
                    }

                    Button {
                        withAnimation {
                            _ = items.popLast()
                        }
                    } label: {
                        Image(systemName: "minus")
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
}

#endif
