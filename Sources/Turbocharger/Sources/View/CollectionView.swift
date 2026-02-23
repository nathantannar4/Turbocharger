//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

#if os(iOS)

/// A bridging view to `UICollectionView` that renders cells in a `UIHostingConfiguration`
///
/// ``CollectionView`` offers better performance than `LazyVStack` since it is able to recycle views
/// and only keep in memory whats on screen.
///
/// > Tip: For improved diffing performance, your data should conform
/// to `Equatable` and `Identifiable`
///
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct CollectionView<
    Header: View,
    Content: View,
    Footer: View,
    SupplementaryView: View,
    Layout: CollectionViewLayout,
    Section: Equatable & Identifiable,
    Items: RandomAccessCollection
>: View where
    Items.Index: Hashable & Sendable,
    Items.Element: Equatable & Identifiable,
    Items.Element.ID: Equatable & Sendable,
    Section.ID: Equatable & Sendable,
    Layout.UICollectionViewCellType: UICollectionViewCell,
    Layout.UICollectionViewSupplementaryViewType: UICollectionViewCell
{
    var layout: Layout
    var sections: [CollectionViewSection<Section, Items>]
    var header: (IndexPath, CollectionViewSection<Section, Items>) -> Header
    var content: (IndexPath, CollectionViewSection<Section, Items>, Items.Element) -> Content
    var footer: (IndexPath, CollectionViewSection<Section, Items>) -> Footer
    var supplementaryViews: [CollectionViewSupplementaryView]
    var supplementaryView: (IndexPath, CollectionViewSection<Section, Items>, CollectionViewSupplementaryView.ID) -> SupplementaryView
    private var modifiers = CollectionViewModifierFields<Section, Items>()

    public init(
        _ layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        supplementaryViews: [CollectionViewSupplementaryView],
        @ViewBuilder content: @escaping (IndexPath, CollectionViewSection<Section, Items>, Items.Element) -> Content,
        @ViewBuilder header: @escaping (IndexPath, CollectionViewSection<Section, Items>) -> Header,
        @ViewBuilder footer: @escaping (IndexPath, CollectionViewSection<Section, Items>) -> Footer,
        @ViewBuilder supplementaryView: @escaping (IndexPath, CollectionViewSection<Section, Items>, CollectionViewSupplementaryView.ID) -> SupplementaryView
    ) {
        self.layout = layout
        self.sections = sections
        self.header = header
        self.content = content
        self.footer = footer
        self.supplementaryViews = supplementaryViews
        self.supplementaryView = supplementaryView
    }

    public init(
        _ layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        @ViewBuilder content: @escaping (IndexPath, CollectionViewSection<Section, Items>, Items.Element) -> Content,
        @ViewBuilder header: @escaping (IndexPath, CollectionViewSection<Section, Items>) -> Header,
        @ViewBuilder footer: @escaping (IndexPath, CollectionViewSection<Section, Items>) -> Footer
    ) where SupplementaryView == EmptyView {
        self.init(
            layout,
            sections: sections,
            supplementaryViews: [],
            content: content,
            header: header,
            footer: footer,
            supplementaryView: { _, _, _ in EmptyView() }
        )
    }

    public var body: some View {
        CollectionViewBody(
            layout: layout,
            sections: sections,
            header: header,
            content: content,
            footer: footer,
            supplementaryViews: supplementaryViews,
            supplementaryView: supplementaryView,
            modifiers: modifiers
        )
    }
}

@available(iOS 14.0, *)
extension CollectionView {

    public func onSelect(
        isEnabled: Bool = true,
        action: ((IndexPath, Items.Element) -> Void)?
    ) -> Self {
        var copy = self
        copy.modifiers.onSelect = isEnabled ? action : nil
        return copy
    }

    public func onSelect(
        isEnabled: @escaping (IndexPath, Items.Element) -> CollectionViewSelectionAvailability,
        action: ((IndexPath, Items.Element) -> Void)?
    ) -> Self {
        var copy = self
        copy.modifiers.canSelect = isEnabled
        copy.modifiers.onSelect = action
        return copy
    }

    public func onRefresh(
        isEnabled: Bool = true,
        action: (@MainActor @Sendable () async -> Void)?
    ) -> Self {
        var copy = self
        copy.modifiers.onRefresh = isEnabled ? action : nil
        return copy
    }

    public func onItemWillAppear(
        isEnabled: Bool = true,
        action: ((IndexPath, CollectionViewSection<Section, Items>, Items.Element) -> Void)?
    ) -> Self {
        var copy = self
        copy.modifiers.onItemWillAppear = isEnabled ? action : nil
        return copy
    }

    public func dataPrefetcher(
        _ dataPrefetcher: (any CollectionViewDataPrefetcher<Items.Element>)?
    ) -> Self {
        var copy = self
        copy.modifiers.dataPrefetcher = dataPrefetcher
        return copy
    }

    public func onReorder(
        isEnabled: Bool = true,
        action: ((_ from: (section: Int, indices: IndexSet), _ to: (section: Int, destination: Int)) -> Void)?
    ) -> Self {
        var copy = self
        copy.modifiers.onReorder = isEnabled ? action : nil
        return copy
    }

    public func onScrollContentOffsetChange(
        action: ((EdgeInsets, CGPoint) -> Void)?
    ) -> Self {
        var copy = self
        copy.modifiers.onScroll = action
        return copy
    }

    public func sectionScrollPosition(
        _ sectionScrollPosition: Binding<Section.ID?>?
    ) -> Self {
        var copy = self
        copy.modifiers.sectionScrollPosition = sectionScrollPosition.map { .init($0) }
        return copy
    }

    public func sectionScrollPosition(
        _ sectionScrollPosition: PublishedState<Section.ID?>.Binding?
    ) -> Self {
        var copy = self
        copy.modifiers.sectionScrollPosition = sectionScrollPosition.map { .init($0) }
        return copy
    }

    public func itemScrollPosition(
        _ itemScrollPosition: Binding<Items.Element.ID?>?
    ) -> Self {
        var copy = self
        copy.modifiers.itemScrollPosition = itemScrollPosition.map { .init($0) }
        return copy
    }

    public func itemScrollPosition(
        _ itemScrollPosition: PublishedState<Items.Element.ID?>.Binding?
    ) -> Self {
        var copy = self
        copy.modifiers.itemScrollPosition = itemScrollPosition.map { .init($0) }
        return copy
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionView {

    public init(
        _ layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        @ViewBuilder content: @escaping (IndexPath, CollectionViewSection<Section, Items>, Items.Element) -> Content
    ) where
        Header == EmptyView,
        Footer == EmptyView,
        SupplementaryView == EmptyView
    {
        self.init(
            layout,
            sections: sections,
            content: content,
            header: { _, _ in EmptyView() },
            footer: { _, _ in EmptyView() }
        )
    }

    public init(
        _ layout: Layout,
        supplementaryViews: [CollectionViewSupplementaryView],
        items: Items,
        @ViewBuilder content: @escaping (IndexPath, CollectionViewSection<Section, Items>, Items.Element) -> Content,
        @ViewBuilder header: @escaping (IndexPath, CollectionViewSection<Section, Items>) -> Header,
        @ViewBuilder footer: @escaping (IndexPath, CollectionViewSection<Section, Items>) -> Footer,
        @ViewBuilder supplementaryView: @escaping (IndexPath, CollectionViewSection<Section, Items>, CollectionViewSupplementaryView.ID) -> SupplementaryView
    ) where
        Section == CollectionViewSectionIndex
    {
        self.init(
            layout,
            sections: [
                CollectionViewSection(items: items, section: 0)
            ],
            supplementaryViews: supplementaryViews,
            content: content,
            header: header,
            footer: footer,
            supplementaryView: supplementaryView
        )
    }

    public init(
        _ layout: Layout,
        items: Items,
        @ViewBuilder content: @escaping (IndexPath, CollectionViewSection<Section, Items>, Items.Element) -> Content,
        @ViewBuilder header: @escaping (IndexPath, CollectionViewSection<Section, Items>) -> Header,
        @ViewBuilder footer: @escaping (IndexPath, CollectionViewSection<Section, Items>) -> Footer
    ) where
        Section == CollectionViewSectionIndex,
        SupplementaryView == EmptyView
    {
        self.init(
            layout,
            supplementaryViews: [],
            items: items,
            content: content,
            header: header,
            footer: footer,
            supplementaryView: { _, _, _ in EmptyView() }
        )
    }

    public init(
        _ layout: Layout,
        items: Items,
        @ViewBuilder content: @escaping (IndexPath, CollectionViewSection<Section, Items>, Items.Element) -> Content
    ) where
        Section == CollectionViewSectionIndex,
        Header == EmptyView,
        Footer == EmptyView,
        SupplementaryView == EmptyView
    {
        self.init(
            layout,
            items: items,
            content: content,
            header: { _, _ in EmptyView() },
            footer: { _, _ in EmptyView() }
        )
    }

    public init<
        Views: View
    >(
        _ layout: Layout,
        @ViewBuilder views: () -> Views
    ) where
        Section == CollectionViewSectionIndex,
        Content == MultiViewSubviewVisitor.Subview,
        Items == Array<EquatableBox<MultiViewSubviewVisitor.Subview>>,
        Header == EmptyView,
        Footer == EmptyView,
        SupplementaryView == EmptyView
    {
        var visitor = MultiViewSubviewVisitor()
        let content = views()
        content.visit(visitor: &visitor)
        let items = visitor.subviews.map { EquatableBox($0) }
        self.init(
            layout,
            items: items,
            content: { $2.value }
        )
    }

    public init(
        _ layout: Layout,
        views: VariadicView,
        content: @escaping (VariadicView.Subview) -> Content = { $0 }
    ) where
        Section == CollectionViewSectionIndex,
        Items == Array<EquatableBox<VariadicView.Subview>>,
        Header == EmptyView,
        Footer == EmptyView,
        SupplementaryView == EmptyView
    {
        let items = views.map { EquatableBox($0) }
        self.init(
            layout,
            items: items,
            content: { content($2.value) }
        )
    }
}

@available(iOS 14.0, *)
public enum CollectionViewSelectionAvailability {
    case unavailable
    case disabled
    case available
}

@available(iOS 14.0, *)
private struct CollectionViewModifierFields<
    Section: Equatable & Identifiable,
    Items: RandomAccessCollection
> where
    Items.Index: Hashable & Sendable,
    Items.Element: Equatable & Identifiable,
    Items.Element.ID: Equatable & Sendable,
    Section.ID: Equatable & Sendable
{
    var onSelect: ((IndexPath, Items.Element) -> Void)?
    var canSelect: ((IndexPath, Items.Element) -> CollectionViewSelectionAvailability)?
    var onRefresh: (@MainActor @Sendable () async -> Void)?
    var onItemWillAppear: ((IndexPath, CollectionViewSection<Section, Items>, Items.Element) -> Void)?
    var dataPrefetcher: (any CollectionViewDataPrefetcher<Items.Element>)?
    var onReorder: ((_ from: (Int, IndexSet), _ to: (Int, Int)) -> Void)?
    var onScroll: ((EdgeInsets, CGPoint) -> Void)?
    var sectionScrollPosition: PublishedStateOrBinding<Section.ID?>?
    var itemScrollPosition: PublishedStateOrBinding<Items.Element.ID?>?
}

@available(iOS 14.0, *)
private struct CollectionViewBody<
    Header: View,
    Content: View,
    Footer: View,
    SupplementaryView: View,
    Layout: CollectionViewLayout,
    Section: Equatable & Identifiable,
    Items: RandomAccessCollection,
>: CollectionViewRepresentable where
    Items.Index: Hashable & Sendable,
    Items.Element: Equatable & Identifiable,
    Items.Element.ID: Equatable & Sendable,
    Section.ID: Equatable & Sendable,
    Layout.UICollectionViewCellType: UICollectionViewCell,
    Layout.UICollectionViewSupplementaryViewType: UICollectionViewCell
{

    var layout: Layout
    var sections: [CollectionViewSection<Section, Items>]
    var header: Coordinator.HeaderProvider
    var content: Coordinator.ContentProvider
    var footer: Coordinator.FooterProvider
    var supplementaryViews: [CollectionViewSupplementaryView]
    var supplementaryView: Coordinator.SupplementaryViewProvider
    var modifiers: CollectionViewModifierFields<Section, Items>

    typealias Coordinator = CollectionViewHostingConfigurationCoordinator<Header, Content, Footer, SupplementaryView, Layout, Section, Items>

    var layoutOptions: CollectionViewLayoutOptions {
        var layoutOptions = CollectionViewLayoutOptions(supplementaryViews: supplementaryViews)
        if Header.self != EmptyView.self, !layoutOptions.supplementaryViews.contains(where: { $0.id == .header }) {
            layoutOptions.supplementaryViews.append(.header)
        }
        if Footer.self != EmptyView.self, !layoutOptions.supplementaryViews.contains(where: { $0.id == .footer }) {
            layoutOptions.supplementaryViews.append(.footer)
        }
        return layoutOptions
    }

    func updateCoordinator(_ coordinator: Coordinator) {
        coordinator.header = header
        coordinator.content = content
        coordinator.footer = footer
        coordinator.supplementaryView = supplementaryView
        coordinator.onSelect = modifiers.onSelect
        coordinator.canSelect = modifiers.canSelect
        coordinator.onRefresh = modifiers.onRefresh
        coordinator.onItemWillAppear = modifiers.onItemWillAppear
        coordinator.dataPrefetcher = modifiers.dataPrefetcher
        coordinator.onReorder = modifiers.onReorder
        coordinator.onScroll = modifiers.onScroll
        coordinator.sectionScrollPosition = modifiers.sectionScrollPosition
        coordinator.itemScrollPosition = modifiers.itemScrollPosition
    }

    func makeCoordinator() -> Coordinator {
        CollectionViewHostingConfigurationCoordinator(
            header: header,
            content: content,
            footer: footer,
            supplementaryView: supplementaryView,
            layout: layout,
            sections: sections,
            layoutOptions: layoutOptions
        )
    }
}

#endif

// MARK: - Previews

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CollectionView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewA()
        PreviewB()
        PreviewC()
    }

    struct PreviewA: View {
        struct Item: Identifiable, Equatable {
            var id = UUID().uuidString
            var value = 0
        }

        @State var sections: [CollectionViewSection<CollectionViewSectionIndex, [Item]>] = (0..<10).map { index in
            CollectionViewSection(
                items: (0..<10).map { Item(value: $0) },
                section: index
            )
        }

        struct ItemView: View {
            var item: Item

            @State var isExpanded = false

            var body: some View {
                VStack(spacing: 0) {
                    Text(item.id)
                        .frame(maxWidth: .infinity, minHeight: isExpanded ? 88 : 44)
                        .background(item.value.isMultiple(of: 2) ? .blue : .red)
                }
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
            }
        }

        struct HeaderFooterView: View {
            var index: Int

            @State var isExpanded = false

            var body: some View {
                Text("Header/Footer \(index)")
                    .frame(maxWidth: .infinity, minHeight: isExpanded ? 44 : 22)
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
            }
        }

        var body: some View {
            CollectionView(
                .compositional(
                    contentInsets: .init(top: 4, leading: 4, bottom: 4, trailing: 4),
                    pinnedViews: [
                        .header,
                    ]
                ),
                sections: sections,
                supplementaryViews: [
                    .header(
                        contentInset: .init(top: 4, leading: 4, bottom: 4, trailing: 4)
                    ),
                    .custom(
                        "banner",
                        alignment: .topLeading,
                        offset: CGPoint(x: 0, y: -24),
                        contentInset: .init(top: 0, leading: 12, bottom: 0, trailing: 12)
                    ),
                    .custom(
                        "card",
                        alignment: .bottom,
                        offset: CGPoint(x: 0, y: 24)
                    )
                ]
            ) { indexPath, section, item in
                ItemView(item: item)
            } header: { indexPath, section in
                HeaderFooterView(index: section.id.index)
                    .background(.yellow)
            } footer: { indexPath, section in
                HeaderFooterView(index: section.id.index)
                    .background(.orange)
            } supplementaryView: { indexPath, section, id in
                if id == .custom("banner"), section.id.index == 0 {
                    Color.purple
                        .frame(height: 200)
                        .overlay {
                            Rectangle()
                                .inset(by: 5)
                                .stroke(Color.green, lineWidth: 10)
                        }
                } else if id == .custom("card") {
                    Color.pink
                        .frame(height: 200)
                        .overlay {
                            Rectangle()
                                .inset(by: 5)
                                .stroke(Color.green, lineWidth: 10)
                        }
                }
            }
            .ignoresSafeArea()
        }
    }

    struct PreviewB: View {
        struct Item: Identifiable, Equatable {
            var id = UUID().uuidString
            var value = 0
        }

        @State var items: [Item] = (0..<5).map { Item(value: $0) }

        @State var isExpanded = false

        struct ItemView: View {
            var item: Item

            @State var isExpanded = false

            var body: some View {
                VStack(spacing: 0) {
                    Text(item.id)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)

                    if #available(iOS 16.0, *) {
                        Text(item.value, format: .number)
                            .contentTransition(.numericText())
                    } else {
                        Text(item.value, format: .number)
                    }

                    RoundedRectangle(cornerRadius: isExpanded ? 6 : 0)
                        .fill(.yellow)
                        .frame(height: isExpanded ? 100 : 0)
                        .opacity(isExpanded ? 1 : 0)
                }
                .padding(6)
                .background(item.value.isMultiple(of: 2) ? .blue : .red)
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
            CollectionView(.plain, items: items) { indexPath, section, item in
                ItemView(item: item)
            } header: { indexPath, section in
                HeaderFooterView(text: "Header")
            } footer: { indexPath, section in
                HeaderFooterView(text: "Footer")
            }
            .refreshable {
                items.shuffle()
            }
            .animation(.default, value: items)
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
                            items.append(Item())
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

    struct PreviewC: View {
        struct Item: Identifiable, Equatable {
            var id = UUID().uuidString
            var value = 0
        }

        @State var items: [Item] = (0..<5).map { Item(value: $0) }
        @State var isReordering = false

        var body: some View {
            VStack {
                CollectionView(
                    .compositional.backgroundConfiguration(.selectable),
                    items: items
                ) { indexPath, section, item in
                    CellView(isReordering: isReordering)
                } header: { _, _ in
                    Text("Header")
                } footer: { _, _ in
                    Text("Footer")
                }
                .onSelect { indexPath, item in
                    if indexPath.item == 0 {
                        return .disabled
                    }
                    if indexPath.item == 1 {
                        return .unavailable
                    }
                    return .available
                } action: { _, item in
                    print(item)
                }
                .onReorder(isEnabled: isReordering) { from, to in
                    items.move(
                        fromOffsets: from.indices,
                        toOffset: to.destination
                    )
                }
            }
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                HStack {
                    Button {
                        withAnimation {
                            isReordering.toggle()
                        }
                    } label: {
                        Text("isReordering")
                    }
                }
            }
        }

        struct CellView: View {
            var isReordering: Bool

            @Environment(\.isEnabled) var isEnabled

            var body: some View {
                HStack {
                    Text("Hello, World")
                        .opacity(isEnabled ? 1 : 0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if isReordering {
                        Circle()
                            .frame(width: 20, height: 20)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding()
            }
        }
    }
}

#endif
