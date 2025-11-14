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
    Items.Element.ID: Sendable,
    Section.ID: Sendable,
    Layout.UICollectionViewCellType: UICollectionViewCell,
    Layout.UICollectionViewSupplementaryViewType: UICollectionViewCell
{
    var layout: Layout
    var sections: [CollectionViewSection<Section, Items>]
    var header: (Section) -> Header
    var content: (Items.Element) -> Content
    var footer: (Section) -> Footer
    var supplementaryViews: [CollectionViewSupplementaryView]
    var supplementaryView: (CollectionViewSupplementaryView.ID, Section) -> SupplementaryView
    var refresh: (() async -> Void)?
    var reorder: ((_ from: (Int, IndexSet), _ to: (Int, Int)) -> Void)?

    public init(
        _ layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        supplementaryViews: [CollectionViewSupplementaryView],
        refresh: (() async -> Void)? = nil,
        reorder: ((_ from: (section: Int, indices: IndexSet), _ to: (section: Int, destination: Int)) -> Void)? = nil,
        @ViewBuilder content: @escaping (Items.Element) -> Content,
        @ViewBuilder header: @escaping (Section) -> Header,
        @ViewBuilder footer: @escaping (Section) -> Footer,
        @ViewBuilder supplementaryView: @escaping (CollectionViewSupplementaryView.ID, Section) -> SupplementaryView
    ) {
        self.layout = layout
        self.sections = sections
        self.header = header
        self.content = content
        self.footer = footer
        self.supplementaryViews = supplementaryViews
        self.supplementaryView = supplementaryView
        self.refresh = refresh
        self.reorder = reorder
    }

    public init(
        _ layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        refresh: (() async -> Void)? = nil,
        reorder: ((_ from: (section: Int, indices: IndexSet), _ to: (section: Int, destination: Int)) -> Void)? = nil,
        @ViewBuilder content: @escaping (Items.Element) -> Content,
        @ViewBuilder header: @escaping (Section) -> Header,
        @ViewBuilder footer: @escaping (Section) -> Footer
    ) where SupplementaryView == EmptyView {
        self.init(
            layout,
            sections: sections,
            supplementaryViews: [],
            refresh: refresh,
            reorder: reorder,
            content: content,
            header: header,
            footer: footer,
            supplementaryView: { _, _ in EmptyView() }
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
            refresh: refresh,
            reorder: reorder
        )
    }
}

@available(iOS 14.0, *)
extension CollectionView {

    public func refreshable(
        isEnabled: Bool = true,
        action: @escaping () async -> Void
    ) -> Self {
        var copy = self
        copy.refresh = isEnabled ? action : nil
        return copy
    }

    public func reorderable(
        isEnabled: Bool = true,
        action: @escaping (_ from: (section: Int, indices: IndexSet), _ to: (section: Int, destination: Int)) -> Void
    ) -> Self {
        var copy = self
        copy.reorder = isEnabled ? action : nil
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
        supplementaryViews: [CollectionViewSupplementaryView],
        items: Items,
        refresh: (() async -> Void)? = nil,
        reorder: ((_ from: (section: Int, indices: IndexSet), _ to: (section: Int, destination: Int)) -> Void)? = nil,
        @ViewBuilder content: @escaping (Items.Element) -> Content,
        @ViewBuilder header: @escaping (Section) -> Header,
        @ViewBuilder footer: @escaping (Section) -> Footer,
        @ViewBuilder supplementaryView: @escaping (CollectionViewSupplementaryView.ID, Section) -> SupplementaryView
    ) where
        Section == CollectionViewSectionIndex
    {
        self.init(
            layout,
            sections: [
                CollectionViewSection(items: items, section: 0)
            ],
            supplementaryViews: supplementaryViews,
            refresh: refresh,
            reorder: reorder,
            content: content,
            header: header,
            footer: footer,
            supplementaryView: supplementaryView
        )
    }

    public init(
        _ layout: Layout,
        items: Items,
        refresh: (() async -> Void)? = nil,
        reorder: ((_ from: (section: Int, indices: IndexSet), _ to: (section: Int, destination: Int)) -> Void)? = nil,
        @ViewBuilder content: @escaping (Items.Element) -> Content,
        @ViewBuilder header: @escaping (Section) -> Header,
        @ViewBuilder footer: @escaping (Section) -> Footer
    ) where
        Section == CollectionViewSectionIndex,
        SupplementaryView == EmptyView
    {
        self.init(
            layout,
            supplementaryViews: [],
            items: items,
            refresh: refresh,
            reorder: reorder,
            content: content,
            header: header,
            footer: footer,
            supplementaryView: { _, _ in EmptyView() }
        )
    }

    public init(
        _ layout: Layout,
        items: Items,
        refresh: (() async -> Void)? = nil,
        reorder: ((_ from: (section: Int, indices: IndexSet), _ to: (section: Int, destination: Int)) -> Void)? = nil,
        @ViewBuilder content: @escaping (Items.Element) -> Content
    ) where
        Section == CollectionViewSectionIndex,
        Header == EmptyView,
        Footer == EmptyView,
        SupplementaryView == EmptyView
    {
        self.init(
            layout,
            items: items,
            refresh: refresh,
            reorder: reorder,
            content: content,
            header: { _ in EmptyView() },
            footer: { _ in EmptyView() }
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
            content: { $0.value }
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
            content: { content($0.value) }
        )
    }
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
    Items.Element.ID: Sendable,
    Section.ID: Sendable,
    Layout.UICollectionViewCellType: UICollectionViewCell,
    Layout.UICollectionViewSupplementaryViewType: UICollectionViewCell
{

    var layout: Layout
    var sections: [CollectionViewSection<Section, Items>]
    var header: (Section) -> Header
    var content: (Items.Element) -> Content
    var footer: (Section) -> Footer
    var supplementaryViews: [CollectionViewSupplementaryView]
    var supplementaryView: (CollectionViewSupplementaryView.ID, Section) -> SupplementaryView
    var refresh: (() async -> Void)?
    var reorder: ((_ from: (Int, IndexSet), _ to: (Int, Int)) -> Void)?

    typealias Coordinator = CollectionViewHostingConfigurationCoordinator<Header, Content, Footer, SupplementaryView, Layout, Section, Items>

    func updateCoordinator(_ coordinator: Coordinator) {
        coordinator.header = header
        coordinator.content = content
        coordinator.footer = footer
        coordinator.supplementaryView = supplementaryView
        coordinator.refresh = refresh
        coordinator.reorder = reorder
    }

    func makeCoordinator() -> Coordinator {
        var layoutOptions = CollectionViewLayoutOptions(supplementaryViews: supplementaryViews)
        if Header.self != EmptyView.self, !layoutOptions.supplementaryViews.contains(where: { $0.id == .header }) {
            layoutOptions.supplementaryViews.append(.header)
        }
        if Footer.self != EmptyView.self, !layoutOptions.supplementaryViews.contains(where: { $0.id == .footer }) {
            layoutOptions.supplementaryViews.append(.footer)
        }
        return CollectionViewHostingConfigurationCoordinator(
            header: header,
            content: content,
            footer: footer,
            supplementaryView: supplementaryView,
            layout: layout,
            sections: sections,
            refresh: refresh,
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
            ) { item in
                ItemView(item: item)
            } header: { section in
                HeaderFooterView(index: section.index)
                    .background(.yellow)
            } footer: { section in
                HeaderFooterView(index: section.index)
                    .background(.orange)
            } supplementaryView: { id, section in
                if id == .custom("banner"), section.index == 0 {
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
            CollectionView(.plain, items: items) { item in
                ItemView(item: item)
            } header: { index in
                HeaderFooterView(text: "Header")
            } footer: { index in
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
        @State var flag = false

        var body: some View {
            VStack {
                Button {
                    flag.toggle()
                } label: {
                    Text("Toggle")
                }

                CollectionView(.compositional) {
                    CellView(flag: flag)
                    CellView(flag: flag)
                }
            }
            .animation(.default, value: flag)
        }

        struct CellView: View {
            var flag: Bool

            var body: some View {
                HStack {
                    Text("Hello, World")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if flag {
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
