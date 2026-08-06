//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)

import SwiftUI
import UIKit
import Engine

@available(iOS 14.0, tvOS 14.0, *)
public struct HostingConfigurationStateKey: EnvironmentKey {
    public static var defaultValue: HostingConfigurationState { HostingConfigurationState(storage: .init(traitCollection: .current)) }
}

extension EnvironmentValues {

    @available(iOS 14.0, tvOS 14.0, *)
    public var hostingConfigurationState: HostingConfigurationState {
        get { self[HostingConfigurationStateKey.self] }
        set { self[HostingConfigurationStateKey.self] = newValue }
    }
}

@available(iOS 14.0, tvOS 14.0, *)
public struct CollectionViewHostingConfigurationCoordinatorOptions: OptionSet {
    public var rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    /// Uses a custom `UIContentConfiguration` that reuses SwiftUI content view, preserving things like `@State` and any `UIViewRepresentable`'s
    public static var useReusableHostingConfiguration: CollectionViewHostingConfigurationCoordinatorOptions {
        CollectionViewHostingConfigurationCoordinatorOptions(rawValue: 1 << 0)
    }
}

/// A ``CollectionViewCoordinator`` that manages the rendering of a View
/// for a `UICollectionViewDiffableDataSource`
@available(iOS 14.0, tvOS 14.0, *)
open class CollectionViewHostingConfigurationCoordinator<
    Header: View,
    Content: View,
    Footer: View,
    SupplementaryView: View,
    Layout: CollectionViewLayout,
    Section: Equatable & Identifiable,
    Items: RandomAccessCollection,
    Configuration: CollectionViewCoordinatorConfiguration
>: CollectionViewCoordinator<Layout, Section, Items, Configuration> where
    Items.Index: Hashable & Sendable,
    Items.Element: Equatable & Identifiable,
    Items.Element.ID: Equatable & Sendable,
    Section.ID: Equatable & Sendable,
    Layout.UICollectionViewCellType: UICollectionViewCell,
    Layout.UICollectionViewSupplementaryViewType: UICollectionViewCell,
    Configuration.Item == Items.Element
{

    public typealias HeaderProvider = (IndexPath, CollectionViewSection<Section, Items>) -> Header
    public var header: HeaderProvider
    public typealias ContentProvider = (IndexPath, CollectionViewSection<Section, Items>, Items.Element) -> Content
    public var content: ContentProvider
    public typealias FooterProvider = (IndexPath, CollectionViewSection<Section, Items>) -> Footer
    public var footer: FooterProvider
    public typealias SupplementaryViewProvider = (IndexPath, CollectionViewSection<Section, Items>, CollectionViewSupplementaryView.ID) -> SupplementaryView
    public var supplementaryView: SupplementaryViewProvider

    public var options: CollectionViewHostingConfigurationCoordinatorOptions

    public private(set) var phase = UpdatePhase.Value()

    public init(
        header: @escaping HeaderProvider,
        content: @escaping ContentProvider,
        footer: @escaping FooterProvider,
        supplementaryView: @escaping SupplementaryViewProvider,
        layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        layoutOptions: CollectionViewLayoutOptions,
        options: CollectionViewHostingConfigurationCoordinatorOptions = [],
        configuration: Configuration
    ) {
        self.header = header
        self.content = content
        self.footer = footer
        self.supplementaryView = supplementaryView
        self.options = options
        super.init(
            sections: sections,
            layout: layout,
            layoutOptions: layoutOptions,
            configuration: configuration
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
        layoutOptions: CollectionViewLayoutOptions,
        options: CollectionViewHostingConfigurationCoordinatorOptions = [],
        configuration: Configuration
    ) where SupplementaryView == EmptyView {
        self.init(
            header: header,
            content: content,
            footer: footer,
            supplementaryView: { _, _, _ in EmptyView() },
            layout: layout,
            sections: sections,
            layoutOptions: layoutOptions,
            options: options,
            configuration: configuration
        )
    }

    public convenience init(
        header: @escaping HeaderProvider,
        content: @escaping ContentProvider,
        footer: @escaping FooterProvider,
        layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        layoutOptions: CollectionViewLayoutOptions,
        options: CollectionViewHostingConfigurationCoordinatorOptions = []
    ) where
        SupplementaryView == EmptyView,
        Configuration == CollectionViewCoordinatorDefaultConfiguration<Items.Element>
    {
        self.init(
            header: header,
            content: content,
            footer: footer,
            layout: layout,
            sections: sections,
            layoutOptions: layoutOptions,
            options: options,
            configuration: CollectionViewCoordinatorDefaultConfiguration<Items.Element>()
        )
    }

    public convenience init(
        content: @escaping ContentProvider,
        layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        options: CollectionViewHostingConfigurationCoordinatorOptions = [],
        configuration: Configuration
    ) where
        Header == EmptyView,
        Footer == EmptyView,
        SupplementaryView == EmptyView
    {
        self.init(
            header: { _, _ in EmptyView() },
            content: content,
            footer: { _, _ in EmptyView() },
            supplementaryView: { _, _, _ in EmptyView() },
            layout: layout,
            sections: sections,
            layoutOptions: .init(),
            options: options,
            configuration: configuration
        )
    }

    public convenience init(
        content: @escaping ContentProvider,
        layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        options: CollectionViewHostingConfigurationCoordinatorOptions = []
    ) where
        Header == EmptyView,
        Footer == EmptyView,
        SupplementaryView == EmptyView,
        Configuration == CollectionViewCoordinatorDefaultConfiguration<Items.Element>
    {
        self.init(
            content: content,
            layout: layout,
            sections: sections,
            options: options,
            configuration: CollectionViewCoordinatorDefaultConfiguration<Items.Element>()
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
        cell.contentView.clipsToBounds = false
        cell.clipsToBounds = false
        // Fixes `.transition` modifier
        if context.transaction.isAnimated {
            cell.layoutIfNeeded()
        }
        return cell
    }

    open override func configureCell(
        _ cell: Layout.UICollectionViewCellType,
        indexPath: IndexPath,
        item: Items.Element
    ) {
        super.configureCell(cell, indexPath: indexPath, item: item)
        let section = sections[indexPath.section]
        let bridgedState = HostingConfigurationStateBridge(state: cell.configurationState)
        cell.contentConfiguration = makeContent(
            state: bridgedState,
            indexPath: indexPath,
            section: section,
            value: item
        )
        if #available(iOS 15.0, tvOS 15.0, *) {
            let handler = cell.configurationUpdateHandler
            cell.configurationUpdateHandler = { [weak self, weak bridgedState] cell, state in
                handler?(cell, state)
                guard let self, let bridgedState else { return }
                bridgedState.update(state, defer: isUpdating)
            }
        }
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
        supplementaryView.contentView.clipsToBounds = false
        supplementaryView.clipsToBounds = false
        // Fixes `.transition` modifier
        if context.transaction.isAnimated {
            supplementaryView.layoutIfNeeded()
        }
        return supplementaryView
    }

    open override func configureSupplementaryView(
        _ supplementaryView: Layout.UICollectionViewSupplementaryViewType,
        kind: String,
        indexPath: IndexPath
    ) {
        super.configureSupplementaryView(supplementaryView, kind: kind, indexPath: indexPath)
        let section = sections[indexPath.section]
        let bridgedState = HostingConfigurationStateBridge(state: supplementaryView.configurationState)
        supplementaryView.contentConfiguration = makeSupplementaryContent(
            state: bridgedState,
            indexPath: indexPath,
            section: section,
            kind: kind
        )
        if #available(iOS 15.0, tvOS 15.0, *) {
            let handler = supplementaryView.configurationUpdateHandler
            supplementaryView.configurationUpdateHandler = { [weak self, weak bridgedState] supplementaryView, state in
                handler?(supplementaryView, state)
                guard let self, let bridgedState else { return }
                bridgedState.update(state, defer: isUpdating)
            }
        }
    }

    open override func didStartUpdate() {
        super.didStartUpdate()
        phase.update()
    }

    open override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        super.collectionView(collectionView, didSelectItemAt: indexPath)

        if #unavailable(iOS 15.0, tvOS 15.0) {
            guard let cell = collectionView.cellForItem(at: indexPath) as? Layout.UICollectionViewCellType else { return }
            let item = item(for: indexPath)
            self.configureCell(cell, indexPath: indexPath, item: item)
            cell.layoutIfNeeded()
        }
    }

    open override func collectionView(
        _ collectionView: UICollectionView,
        didDeselectItemAt indexPath: IndexPath
    ) {
        super.collectionView(collectionView, didDeselectItemAt: indexPath)

        if #unavailable(iOS 15.0, tvOS 15.0) {
            guard let cell = collectionView.cellForItem(at: indexPath) as? Layout.UICollectionViewCellType else { return }
            let item = item(for: indexPath)
            self.configureCell(cell, indexPath: indexPath, item: item)
            cell.layoutIfNeeded()
        }
    }

    open override func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)

        if #unavailable(iOS 15.0, tvOS 15.0) {
            guard let cell = cell as? Layout.UICollectionViewCellType else { return }
            let item = item(for: indexPath)
            self.configureCell(cell, indexPath: indexPath, item: item)
            cell.layoutIfNeeded()
        }
    }

    open override func collectionView(
        _ collectionView: UICollectionView,
        willDisplaySupplementaryView view: UICollectionReusableView,
        forElementKind elementKind: String,
        at indexPath: IndexPath
    ) {
        super.collectionView(collectionView, willDisplaySupplementaryView: view, forElementKind: elementKind, at: indexPath)

        if #unavailable(iOS 15.0, tvOS 15.0) {
            guard let supplementaryView = view as? Layout.UICollectionViewSupplementaryViewType else { return }
            self.configureSupplementaryView(supplementaryView, kind: elementKind, indexPath: indexPath)
            supplementaryView.layoutIfNeeded()
        }
    }

    private func makeContent(
        state: HostingConfigurationStateBridge,
        indexPath: IndexPath,
        section: CollectionViewSection<Section, Items>,
        value: Items.Element
    ) -> UIContentConfiguration {
        makeHostingConfiguration(
            id: value.id,
            state: state,
            transaction: context.transaction,
            phase: phase,
            options: options
        ) {
            content(indexPath, section, value)
        }
    }

    private func makeSupplementaryContent(
        state: HostingConfigurationStateBridge,
        indexPath: IndexPath,
        section: CollectionViewSection<Section, Items>,
        kind: String
    ) -> UIContentConfiguration {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            return makeHeaderContent(
                state: state,
                indexPath: indexPath,
                section: section
            )
        case UICollectionView.elementKindSectionFooter:
            return makeFooterContent(
                state: state,
                indexPath: indexPath,
                section: section
            )
        default:
            return makeCustomSupplementaryContent(
                state: state,
                indexPath: indexPath,
                section: section,
                kind: kind
            )
        }
    }

    private func makeHeaderContent(
        state: HostingConfigurationStateBridge,
        indexPath: IndexPath,
        section: CollectionViewSection<Section, Items>
    ) -> UIContentConfiguration {
        makeHostingConfiguration(
            id: SupplementaryViewID(
                id: section.section.id,
                kind: CollectionViewSupplementaryView.ID.header
            ),
            state: state,
            transaction: context.transaction,
            phase: phase,
            options: options
        ) {
            header(indexPath, section)
        }
    }

    private func makeFooterContent(
        state: HostingConfigurationStateBridge,
        indexPath: IndexPath,
        section: CollectionViewSection<Section, Items>,
    ) -> UIContentConfiguration {
        makeHostingConfiguration(
            id: SupplementaryViewID(
                id: section.section.id,
                kind: CollectionViewSupplementaryView.ID.footer
            ),
            state: state,
            transaction: context.transaction,
            phase: phase,
            options: options
        ) {
            footer(indexPath, section)
        }
    }

    private func makeCustomSupplementaryContent(
        state: HostingConfigurationStateBridge,
        indexPath: IndexPath,
        section: CollectionViewSection<Section, Items>,
        kind: String
    ) -> UIContentConfiguration {
        makeHostingConfiguration(
            id: SupplementaryViewID(
                id: section.section.id,
                kind: CollectionViewSupplementaryView.ID.custom(kind)
            ),
            state: state,
            transaction: context.transaction,
            phase: phase,
            options: options
        ) {
            supplementaryView(indexPath, section, .custom(kind))
        }
    }
}

extension Animation {

    /// An `Animation` that closely mirrors the cell resize animation
    public static var collectionViewCellSizeInvalidation: Animation {
        .interactiveSpring(duration: 0.25, extraBounce: 0.1, blendDuration: 0.25)
    }
}

@available(iOS 14.0, tvOS 14.0, *)
private struct SupplementaryViewID<ID: Hashable>: Hashable {
    var id: ID
    var kind: CollectionViewSupplementaryView.ID
}

@available(iOS 14.0, tvOS 14.0, *)
private class HostingConfigurationStateBridge: ObservableObject {
    private(set) var state: UICellConfigurationState

    init(state: UICellConfigurationState) {
        self.state = state
    }

    func update(_ newValue: UICellConfigurationState, defer shouldDefer: Bool) {
        guard state != newValue else { return }
        state = newValue
        if shouldDefer {
            withCATransaction { [objectWillChange] in
                objectWillChange.send()
            }
        } else {
            objectWillChange.send()
        }
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@MainActor
private func makeHostingConfiguration<
    ID: Hashable,
    Content: View
>(
    id: ID,
    state: HostingConfigurationStateBridge,
    transaction: Transaction,
    phase: UpdatePhase.Value,
    options: CollectionViewHostingConfigurationCoordinatorOptions,
    @ViewBuilder content: () -> Content
) -> UIContentConfiguration {

    let content = content()
    if #available(iOS 16.0, tvOS 16.0, *), !options.contains(.useReusableHostingConfiguration) {
        let configuration = UIHostingConfiguration {
            content
                .modifier(
                    CollectionViewHostingConfigurationModifier(
                        id: id,
                        isEmpty: content.isEmptyView,
                        state: state,
                        transaction: transaction,
                        phase: phase
                    )
                )
        }
        .margins(.all, 0)
        return configuration
    } else {
        return HostingConfiguration {
            content
                .modifier(
                    CollectionViewHostingConfigurationModifier(
                        id: id,
                        isEmpty: content.isEmptyView,
                        state: state,
                        transaction: transaction,
                        phase: phase
                    )
                )
        }
    }
}

@available(iOS 14.0, tvOS 14.0, *)
private struct CollectionViewHostingConfigurationModifier<ID: Hashable>: ViewModifier {
    var id: ID
    var isEmpty: Bool
    @ObservedObject var state: HostingConfigurationStateBridge
    var transaction: Transaction
    var phase: UpdatePhase.Value

    func body(content: Content) -> some View {
        content
            .environment(\.hostingConfigurationState, HostingConfigurationState(storage: state.state))
            .disabled(state.state.isDisabled)
            .opacity(isEmpty ? 0 : 1)
            .transaction(transaction.disablesAnimations(true), value: id)
            .transaction(transaction, value: phase)
            .modifier(HostingConfigurationModifier())
            .ignoreHostingConfigurationConstraints()
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@dynamicMemberLookup
public struct HostingConfigurationState: Equatable {

    var storage: UICellConfigurationState

    public subscript<T>(dynamicMember keyPath: KeyPath<UICellConfigurationState, T>) -> T {
        storage[keyPath: keyPath]
    }

    public subscript(key: UIConfigurationStateCustomKey) -> AnyHashable? {
        storage[key]
    }
}

@available(iOS 15.0, tvOS 15.0, *)
struct CollectionViewHostingConfigurationCoordinator_Previews: PreviewProvider {

    static var previews: some View {
        ZStack {
            PreviewA()
        }
        ZStack {
            PreviewB()
        }
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
            CollectionView(
                .compositional(spacing: 8),
                items: items,
//                options: [.useReusableHostingConfiguration]
            ) { indexPath, section, item in
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
                Button {
                    withAnimation(.collectionViewCellSizeInvalidation) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(item.value.description)
                        .frame(maxWidth: .infinity, minHeight: isExpanded ? 88 : 44)
                        .background(Color.blue)
                }
            }
        }

        struct HeaderFooterView: View {
            @State var isExpanded = false

            var body: some View {
                Button {
                    withAnimation(.collectionViewCellSizeInvalidation) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text("Header/Footer")
                        .frame(maxWidth: .infinity, minHeight: isExpanded ? 88 : 44)
                        .background(Color.blue)
                }
            }
        }
    }
}

#endif
