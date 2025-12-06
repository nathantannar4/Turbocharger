//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import Engine

import UIKit
import SwiftUI

@available(iOS 14.0, *)
public struct HostingConfigurationStateKey: EnvironmentKey {
    public static let defaultValue = HostingConfigurationState(storage: .init(traitCollection: .current))
}

extension EnvironmentValues {

    @available(iOS 14.0, *)
    public var hostingConfigurationState: HostingConfigurationState {
        get { self[HostingConfigurationStateKey.self] }
        set { self[HostingConfigurationStateKey.self] = newValue }
    }
}

@available(iOS 14.0, *)
@dynamicMemberLookup
public struct HostingConfigurationState: Equatable, @unchecked Sendable {

    var storage: UICellConfigurationState

    public subscript<T>(dynamicMember keyPath: KeyPath<UICellConfigurationState, T>) -> T {
        storage[keyPath: keyPath]
    }

    public subscript(key: UIConfigurationStateCustomKey) -> AnyHashable? {
        storage[key]
    }
}

/// Ignores the `UIHostingConfiguration` constraints, such as disabling
/// `UIViewControllerRepresentable`'s from being used.
@frozen
public struct IgnoreHostingConfigurationConstraintsModifier: ViewModifier {

    @inlinable
    public init() { }

    public func body(content: Content) -> some View {
        content
            .modifier(Modifier())
    }

    private struct Modifier: ViewInputsModifier {
        nonisolated static func makeInputs(inputs: inout ViewInputs) {
            inputs["IsInHostingConfiguration"] = false
        }
    }
}

extension View {

    /// Ignores the `UIHostingConfiguration` constraints, such as disabling
    /// `UIViewControllerRepresentable`'s from being used.
    @inlinable
    public func ignoreHostingConfigurationConstraints() -> some View {
        modifier(IgnoreHostingConfigurationConstraintsModifier())
    }
}

/// A ``CollectionViewCoordinator`` that manages the rendering of a View
/// for a `UICollectionViewDiffableDataSource`
@available(iOS 14.0, *)
open class CollectionViewHostingConfigurationCoordinator<
    Header: View,
    Content: View,
    Footer: View,
    SupplementaryView: View,
    Layout: CollectionViewLayout,
    Section: Equatable & Identifiable,
    Items: RandomAccessCollection
>: CollectionViewCoordinator<Layout, Section, Items> where
    Items.Index: Hashable & Sendable,
    Items.Element: Equatable & Identifiable,
    Items.Element.ID: Equatable & Sendable,
    Section.ID: Equatable & Sendable,
    Layout.UICollectionViewCellType: UICollectionViewCell,
    Layout.UICollectionViewSupplementaryViewType: UICollectionViewCell
{

    public typealias HeaderProvider = (IndexPath, CollectionViewSection<Section, Items>) -> Header
    public var header: HeaderProvider
    public typealias ContentProvider = (IndexPath, CollectionViewSection<Section, Items>, Items.Element) -> Content
    public var content: ContentProvider
    public typealias FooterProvider = (IndexPath, CollectionViewSection<Section, Items>) -> Footer
    public var footer: FooterProvider
    public typealias SupplementaryViewProvider = (IndexPath, CollectionViewSection<Section, Items>, CollectionViewSupplementaryView.ID) -> SupplementaryView
    public var supplementaryView: SupplementaryViewProvider

    private var update = HostingConfigurationUpdate(animation: nil, value: 0)

    public init(
        header: @escaping HeaderProvider,
        content: @escaping ContentProvider,
        footer: @escaping FooterProvider,
        supplementaryView: @escaping SupplementaryViewProvider,
        layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        layoutOptions: CollectionViewLayoutOptions
    ) {
        self.header = header
        self.content = content
        self.footer = footer
        self.supplementaryView = supplementaryView
        super.init(
            sections: sections,
            layout: layout,
            layoutOptions: layoutOptions
        )

        // Invoke the view builders to trigger SwiftUI's runtime to form a
        // dependency between any DynamicProperty that the @escaping value
        // uses.
        for (index, section) in sections.enumerated() {
            let indexPath = IndexPath(item: 0, section: index)
            _ = header(indexPath, section)
            _ = footer(indexPath, section)

            for supplementaryViewId in layoutOptions.supplementaryViews {
                _ = supplementaryView(indexPath, section, supplementaryViewId.id)
            }

            if let first = section.items.first {
                _ = content(indexPath, section, first)
            }
        }
    }

    public convenience init(
        header: @escaping HeaderProvider,
        content: @escaping ContentProvider,
        footer: @escaping FooterProvider,
        layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        layoutOptions: CollectionViewLayoutOptions
    ) where SupplementaryView == EmptyView {
        self.init(
            header: header,
            content: content,
            footer: footer,
            supplementaryView: { _, _, _ in EmptyView() },
            layout: layout,
            sections: sections,
            layoutOptions: layoutOptions
        )
    }

    public convenience init(
        content: @escaping ContentProvider,
        layout: Layout,
        sections: [CollectionViewSection<Section, Items>]
    ) where Header == EmptyView, Footer == EmptyView, SupplementaryView == EmptyView {
        self.init(
            header: { _, _ in EmptyView() },
            content: content,
            footer: { _, _ in EmptyView() },
            supplementaryView: { _, _, _ in EmptyView() },
            layout: layout,
            sections: sections,
            layoutOptions: .init()
        )
    }

    open override func dequeueReusableCell(
        collectionView: Layout.UICollectionViewType,
        indexPath: IndexPath,
        id: ID
    ) -> Layout.UICollectionViewCellType? {
        guard
            let cell = super.dequeueReusableCell(collectionView: collectionView, indexPath: indexPath, id: id)
        else {
            return nil
        }
        cell.automaticallyUpdatesContentConfiguration = false
        cell.automaticallyUpdatesBackgroundConfiguration = onSelect != nil || canSelect != nil
        cell.contentView.clipsToBounds = false
        cell.clipsToBounds = false
        cell.layoutIfNeeded()
        return cell
    }

    open override func configureCell(
        _ cell: Layout.UICollectionViewCellType,
        indexPath: IndexPath,
        item: Items.Element
    ) {
        super.configureCell(cell, indexPath: indexPath, item: item)
        let section = sections[indexPath.section]
        cell.contentConfiguration = makeContent(
            state: cell.configurationState,
            indexPath: indexPath,
            section: section,
            value: item
        )
    }

    open override func dequeueReusableSupplementaryView(
        collectionView: Layout.UICollectionViewType,
        kind: String,
        indexPath: IndexPath
    ) -> Layout.UICollectionViewSupplementaryViewType? {
        guard
            let supplementaryView = super.dequeueReusableSupplementaryView(collectionView: collectionView, kind: kind, indexPath: indexPath)
        else {
            return nil
        }
        supplementaryView.automaticallyUpdatesContentConfiguration = false
        supplementaryView.automaticallyUpdatesBackgroundConfiguration = false
        supplementaryView.contentView.clipsToBounds = false
        supplementaryView.clipsToBounds = false
        supplementaryView.layoutIfNeeded()
        return supplementaryView
    }

    open override func configureSupplementaryView(
        _ supplementaryView: Layout.UICollectionViewSupplementaryViewType,
        kind: String,
        indexPath: IndexPath
    ) {
        super.configureSupplementaryView(supplementaryView, kind: kind, indexPath: indexPath)
        let section = sections[indexPath.section]
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            supplementaryView.contentConfiguration = makeHeaderContent(
                state: supplementaryView.configurationState,
                indexPath: indexPath,
                section: section
            )
        case UICollectionView.elementKindSectionFooter:
            supplementaryView.contentConfiguration = makeFooterContent(
                state: supplementaryView.configurationState,
                indexPath: indexPath,
                section: section
            )
        default:
            supplementaryView.contentConfiguration = makeSupplementaryContent(
                state: supplementaryView.configurationState,
                indexPath: indexPath,
                section: section,
                kind: kind
            )
        }
    }

    open override func didStartUpdate() {
        super.didStartUpdate()
        update.advance(animation: context.transaction.animation)
    }

    open override func didFinishUpdate() {
        super.didFinishUpdate()
        update.animation = nil
    }

    private func makeContent(
        state: UICellConfigurationState,
        indexPath: IndexPath,
        section: CollectionViewSection<Section, Items>,
        value: Items.Element
    ) -> UIContentConfiguration {
        makeHostingConfiguration(
            id: value.id,
            kind: .item,
            state: state,
            update: update
        ) {
            content(indexPath, section, value)
        }
    }

    private func makeHeaderContent(
        state: UICellConfigurationState,
        indexPath: IndexPath,
        section: CollectionViewSection<Section, Items>
    ) -> UIContentConfiguration {
        makeHostingConfiguration(
            id: section.section.id,
            kind: .supplementaryView(.header),
            state: state,
            update: update
        ) {
            header(indexPath, section)
        }
    }

    private func makeFooterContent(
        state: UICellConfigurationState,
        indexPath: IndexPath,
        section: CollectionViewSection<Section, Items>,
    ) -> UIContentConfiguration {
        makeHostingConfiguration(
            id: section.section.id,
            kind: .supplementaryView(.header),
            state: state,
            update: update
        ) {
            footer(indexPath, section)
        }
    }

    private func makeSupplementaryContent(
        state: UICellConfigurationState,
        indexPath: IndexPath,
        section: CollectionViewSection<Section, Items>,
        kind: String
    ) -> UIContentConfiguration {
        makeHostingConfiguration(
            id: section.section.id,
            kind: .supplementaryView(.custom(kind)),
            state: state,
            update: update
        ) {
            supplementaryView(indexPath, section, .custom(kind))
        }
    }
}

@available(iOS 14.0, *)
@MainActor
private func makeHostingConfiguration<
    ID: Hashable,
    Content: View
>(
    id: ID,
    kind: CollectionViewLayoutElementKind,
    state: UICellConfigurationState,
    update: HostingConfigurationUpdate,
    @ViewBuilder content: () -> Content
) -> UIContentConfiguration {

    let content = content()
    if #available(iOS 16.0, *) {
        return UIHostingConfiguration {
            content
                .modifier(
                    HostingConfigurationModifier(
                        id: id,
                        isEmpty: content.isEmptyView,
                        state: HostingConfigurationState(storage: state),
                        update: update
                    )
                )
        }
        .background(.clear)
        .margins(.all, 0)
    } else {
        return HostingConfigurationBackport(kind: kind) {
            content
                .modifier(
                    HostingConfigurationModifier(
                        id: id,
                        isEmpty: content.isEmptyView,
                        state: HostingConfigurationState(storage: state),
                        update: update
                    )
                )
        }
    }
}

private struct HostingConfigurationUpdate {
    var animation: Animation?
    var value: UInt

    mutating func advance(animation: Animation?) {
        self.animation = animation
        self.value = value &+ 1
    }
}

@available(iOS 14.0, *)
private struct HostingConfigurationModifier<ID: Hashable>: ViewModifier {
    var id: ID
    var isEmpty: Bool
    var state: HostingConfigurationState
    var update: HostingConfigurationUpdate

    func body(content: Content) -> some View {
        content
            .environment(\.hostingConfigurationState, state)
            .disabled(state.isDisabled)
            .opacity(isEmpty ? 0 : 1)
            .transition(.identity)
            .id(id)
            .animation(nil, value: id)
            .animation(update.animation, value: update.value)
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct HostingConfigurationBackport<
    Content: View
>: UIContentConfiguration {

    var kind: CollectionViewLayoutElementKind
    var content: Content

    init(
        kind: CollectionViewLayoutElementKind,
        @ViewBuilder content: () -> Content
    ) {
        self.kind = kind
        self.content = content()
    }

    func makeContentView() -> UIView & UIContentView {
        return HostingConfigurationBackportContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> Self {
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
        guard !(abs(size.height - frame.size.height) <= 1e-5) else {
            return
        }

        let kind = (configuration as! HostingConfigurationBackport<Content>).kind
        let ctx = UICollectionViewLayoutInvalidationContext()
        switch kind {
        case .supplementaryView(let supplementaryViewId):
            guard
                let supplementaryView = superview as? UICollectionReusableView,
                let collectionView = supplementaryView.superview as? UICollectionView,
                let indexPath = collectionView.indexPath(forSupplementaryView: supplementaryView)
            else {
                return
            }
            ctx.invalidateSupplementaryElements(ofKind: supplementaryViewId.kind, at: [indexPath])
            collectionView.collectionViewLayout.invalidateLayout(with: ctx)
            supplementaryView.layoutIfNeeded()

        case .item:
            guard
                let collectionViewCell = superview as? UICollectionViewCell,
                let collectionView = collectionViewCell.superview as? UICollectionView,
                let indexPath = collectionView.indexPath(for: collectionViewCell)
            else {
                return
            }
            ctx.invalidateItems(at: [indexPath])
            collectionView.collectionViewLayout.invalidateLayout(with: ctx)
            collectionViewCell.layoutIfNeeded()
        }
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

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CollectionViewHostingConfigurationCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        PreviewA()
        PreviewB()
    }

    struct PreviewA: View {
        struct Item: Identifiable, Equatable {
            var id = UUID().uuidString
            var value = 0
        }

        @State var items: [Item] = (0..<5).map { Item(value: $0) }

        var body: some View {
            CollectionView(
                .compositional(pinnedViews: [.header]),
                items: items
            ) { indexPath, section, item in
                Text(item.id)
                    .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                    .background(alignment: .bottom) {
                        if item.id != section.items.last?.id {
                            Divider()
                        }
                    }
            } header: { indexPath, index in
                Text("Header")
                    .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                    .background(Material.ultraThin)
            } footer: { indexPath, index in
                Text("Footer")
                    .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
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

        var body: some View {
            CollectionView(.compositional(spacing: 8), items: items) { indexPath, section, item in
                CellView(item: item)
            } header: { _, _ in
                HeaderFooterView()
            } footer: { _, _ in
                HeaderFooterView()
            }
        }

        struct CellView: View {
            var item: Item

            @State var isExpanded = false

            var body: some View {
                Text(item.value.description)
                    .frame(maxWidth: .infinity, minHeight: isExpanded ? 88 : 44)
                    .background(Color.blue)
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
            }
        }

        struct HeaderFooterView: View {
            @State var isExpanded = false

            var body: some View {
                Text("Header/Footer")
                    .frame(maxWidth: .infinity, minHeight: isExpanded ? 88 : 44)
                    .background(Color.blue)
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
            }
        }
    }
}

#endif
