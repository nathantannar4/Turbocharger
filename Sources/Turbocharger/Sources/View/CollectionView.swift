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
    Data: RandomAccessCollection
>: View where
    Data.Element: RandomAccessCollection,
    Data.Index: Hashable,
    Data.Element.Element: Equatable & Identifiable,
    Layout.UICollectionViewCellType: UICollectionViewCell,
    Layout.UICollectionViewSupplementaryViewType: UICollectionViewCell
{
    var layout: Layout
    var data: Data
    var header: (Data.Index) -> Header
    var content: (Data.Element.Element) -> Content
    var footer: (Data.Index) -> Footer
    var supplementaryViews: [CollectionViewSupplementaryView]
    var supplementaryView: (CollectionViewSupplementaryView.ID, Data.Index) -> SupplementaryView
    var refresh: (() async -> Void)?

    public init(
        _ layout: Layout,
        sections: Data,
        supplementaryViews: [CollectionViewSupplementaryView],
        refresh: (() async -> Void)? = nil,
        @ViewBuilder content: @escaping (Data.Element.Element) -> Content,
        @ViewBuilder header: @escaping (Data.Index) -> Header,
        @ViewBuilder footer: @escaping (Data.Index) -> Footer,
        @ViewBuilder supplementaryView: @escaping (CollectionViewSupplementaryView.ID, Data.Index) -> SupplementaryView
    ) {
        self.layout = layout
        self.data = sections
        self.header = header
        self.content = content
        self.footer = footer
        self.supplementaryViews = supplementaryViews
        self.supplementaryView = supplementaryView
        self.refresh = refresh
    }

    public init(
        _ layout: Layout,
        sections: Data,
        @ViewBuilder content: @escaping (Data.Element.Element) -> Content,
        @ViewBuilder header: @escaping (Data.Index) -> Header,
        @ViewBuilder footer: @escaping (Data.Index) -> Footer
    ) where SupplementaryView == EmptyView {
        self.init(
            layout,
            sections: sections,
            supplementaryViews: [],
            content: content,
            header: header,
            footer: footer,
            supplementaryView: { _, _ in EmptyView() }
        )
    }

    public var body: some View {
        CollectionViewBody(
            layout: layout,
            data: data,
            header: header,
            content: content,
            footer: footer,
            supplementaryViews: supplementaryViews,
            supplementaryView: supplementaryView,
            refresh: refresh
        )
    }
}

@available(iOS 14.0, *)
extension CollectionView {

    public func refreshable(action: @escaping @Sendable () async -> Void) -> some View {
        var copy = self
        copy.refresh = action
        return copy
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionView where SupplementaryView == EmptyView {

    public init<
        Items: RandomAccessCollection
    >(
        _ layout: Layout,
        items: Items,
        @ViewBuilder content: @escaping (Items.Element) -> Content,
        @ViewBuilder header: @escaping (Data.Index) -> Header,
        @ViewBuilder footer: @escaping (Data.Index) -> Footer
    ) where Items.Element: Equatable & Identifiable, Data == Array<Items>
    {
        self.init(layout, sections: [items], content: content, header: header, footer: footer)
    }

    @_disfavoredOverload
    public init<
        Items: RandomAccessCollection
    >(
        _ layout: Layout,
        items: Items,
        @ViewBuilder content: @escaping (Items.Element) -> Content,
        @ViewBuilder header: @escaping (Data.Index) -> Header,
        @ViewBuilder footer: @escaping (Data.Index) -> Footer
    ) where Items.Element: Identifiable, Data == Array<Array<EquatableBox<Items.Element>>>
    {
        let items = items.map { EquatableBox($0) }
        self.init(layout, sections: [items], content: { content($0.value) }, header: header, footer: footer)
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionView where SupplementaryView == EmptyView {

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
    ) where Sections.Element: RandomAccessCollection, Sections.Index: Hashable, Sections.Element.Element: Equatable, Data == Array<Array<IdentifiableBox<Sections.Element.Element, ID>>>
    {
        let data: Data = sections.compactMap { items in
            items.compactMap { IdentifiableBox($0, id: id) }
        }
        self.init(layout, sections: data, content: { content($0.value) }, header: header, footer: footer)
    }

    @_disfavoredOverload
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
    ) where Sections.Element: RandomAccessCollection, Sections.Index: Hashable, Data == Array<Array<EquatableBox<IdentifiableBox<Sections.Element.Element, ID>>>>
    {
        let data: Data = sections.compactMap { items in
            items.compactMap { EquatableBox(IdentifiableBox($0, id: id)) }
        }
        self.init(layout, sections: data, content: { content($0.value.value) }, header: header, footer: footer)
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionView where Header == EmptyView, Footer == EmptyView, SupplementaryView == EmptyView {

    public init<
        Items: RandomAccessCollection
    >(
        _ layout: Layout,
        items: Items,
        @ViewBuilder content: @escaping (Items.Element) -> Content
    ) where Items.Element: Equatable & Identifiable, Data == Array<Items>
    {
        self.init(layout, items: items, content: content, header: { _ in EmptyView() }, footer: { _ in EmptyView() })
    }

    @_disfavoredOverload
    public init<
        Items: RandomAccessCollection
    >(
        _ layout: Layout,
        items: Items,
        @ViewBuilder content: @escaping (Items.Element) -> Content
    ) where Items.Element: Identifiable, Data == Array<Array<EquatableBox<Items.Element>>>
    {
        let items = items.map { EquatableBox($0) }
        self.init(layout, items: items, content: { content($0.value) }, header: { _ in EmptyView() }, footer: { _ in EmptyView() })
    }

    public init<
        Items: RandomAccessCollection,
        ID: Hashable
    >(
        _ layout: Layout,
        items: Items,
        id: KeyPath<Items.Element, ID>,
        @ViewBuilder content: @escaping (Items.Element) -> Content
    ) where Data == Array<Array<IdentifiableBox<Items.Element, ID>>>
    {
        self.init(layout, sections: [items], id: id, content: content, header: { _ in EmptyView() }, footer: { _ in EmptyView() })
    }

    @_disfavoredOverload
    public init<
        Items: RandomAccessCollection,
        ID: Hashable
    >(
        _ layout: Layout,
        items: Items,
        id: KeyPath<Items.Element, ID>,
        @ViewBuilder content: @escaping (Items.Element) -> Content
    ) where Data == Array<Array<EquatableBox<IdentifiableBox<Items.Element, ID>>>>
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
        Data == Array<Array<EquatableBox<MultiViewSubviewVisitor.Subview>>>
    {
        var visitor = MultiViewSubviewVisitor()
        let content = views()
        content.visit(visitor: &visitor)
        self.init(layout, items: visitor.subviews, content: { $0 })
    }
}

@available(iOS 14.0, *)
private struct CollectionViewBody<
    Header: View,
    Content: View,
    Footer: View,
    SupplementaryView: View,
    Layout: CollectionViewLayout,
    Data: RandomAccessCollection
>: CollectionViewRepresentable where
    Data.Element: RandomAccessCollection,
    Data.Index: Hashable,
    Data.Element.Element: Equatable & Identifiable,
    Layout.UICollectionViewCellType: UICollectionViewCell,
    Layout.UICollectionViewSupplementaryViewType: UICollectionViewCell
{

    var layout: Layout
    var data: Data
    var header: (Data.Index) -> Header
    var content: (Data.Element.Element) -> Content
    var footer: (Data.Index) -> Footer
    var supplementaryViews: [CollectionViewSupplementaryView]
    var supplementaryView: (CollectionViewSupplementaryView.ID, Data.Index) -> SupplementaryView
    var refresh: (() async -> Void)?

    typealias Coordinator = CollectionViewHostingConfigurationCoordinator<Header, Content, Footer, SupplementaryView, Layout, Data>

    func updateCoordinator(_ coordinator: Coordinator) {
        coordinator.header = header
        coordinator.content = content
        coordinator.footer = footer
        coordinator.supplementaryView = supplementaryView
        coordinator.refresh = refresh
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
            data: data,
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
    }

    struct PreviewA: View {
        struct Item: Identifiable, Equatable {
            var id = UUID().uuidString
            var value = 0
        }

        @State var sections: [CollectionViewSection<[Item], Int>] = (0..<10).map { index in
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
            } header: { index in
                HeaderFooterView(index: index)
                    .background(.yellow)
            } footer: { index in
                HeaderFooterView(index: index)
                    .background(.orange)
            } supplementaryView: { id, index in
                if id == .custom("banner"), index == 0 {
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
}

#endif
