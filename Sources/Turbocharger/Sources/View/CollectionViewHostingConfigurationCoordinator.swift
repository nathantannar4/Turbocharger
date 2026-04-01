//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(visionOS)

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

public struct CollectionViewHostingConfigurationCoordinatorOptions: OptionSet, Sendable {
    public var rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    /// Uses a custom `UIContentConfiguration` that reuses SwiftUI content view, preserving things like `@State` and any `UIViewRepresentable`'s
    public static let useReusableHostingConfiguration = CollectionViewHostingConfigurationCoordinatorOptions(rawValue: 1 << 0)
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

    public var options: CollectionViewHostingConfigurationCoordinatorOptions

    public private(set) var updatePhase = UpdatePhase.Value()

    public init(
        header: @escaping HeaderProvider,
        content: @escaping ContentProvider,
        footer: @escaping FooterProvider,
        supplementaryView: @escaping SupplementaryViewProvider,
        layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        layoutOptions: CollectionViewLayoutOptions,
        options: CollectionViewHostingConfigurationCoordinatorOptions
    ) {
        self.header = header
        self.content = content
        self.footer = footer
        self.supplementaryView = supplementaryView
        self.options = options
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
        layoutOptions: CollectionViewLayoutOptions,
        options: CollectionViewHostingConfigurationCoordinatorOptions
    ) where SupplementaryView == EmptyView {
        self.init(
            header: header,
            content: content,
            footer: footer,
            supplementaryView: { _, _, _ in EmptyView() },
            layout: layout,
            sections: sections,
            layoutOptions: layoutOptions,
            options: options
        )
    }

    public convenience init(
        content: @escaping ContentProvider,
        layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        options: CollectionViewHostingConfigurationCoordinatorOptions
    ) where Header == EmptyView, Footer == EmptyView, SupplementaryView == EmptyView {
        self.init(
            header: { _, _ in EmptyView() },
            content: content,
            footer: { _, _ in EmptyView() },
            supplementaryView: { _, _, _ in EmptyView() },
            layout: layout,
            sections: sections,
            layoutOptions: .init(),
            options: options
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
        updatePhase.update()
    }

    private func makeContent(
        state: UICellConfigurationState,
        indexPath: IndexPath,
        section: CollectionViewSection<Section, Items>,
        value: Items.Element
    ) -> UIContentConfiguration {
        makeHostingConfiguration(
            id: value.id,
            state: state,
            transaction: context.transaction,
            updatePhase: updatePhase,
            useReusableHostingConfiguration: options.contains(.useReusableHostingConfiguration)
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
            state: state,
            transaction: context.transaction,
            updatePhase: updatePhase,
            useReusableHostingConfiguration: options.contains(.useReusableHostingConfiguration)
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
            state: state,
            transaction: context.transaction,
            updatePhase: updatePhase,
            useReusableHostingConfiguration: options.contains(.useReusableHostingConfiguration)
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
            state: state,
            transaction: context.transaction,
            updatePhase: updatePhase,
            useReusableHostingConfiguration: options.contains(.useReusableHostingConfiguration)
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
    state: UICellConfigurationState,
    transaction: Transaction,
    updatePhase: UpdatePhase.Value,
    useReusableHostingConfiguration: Bool,
    @ViewBuilder content: () -> Content
) -> UIContentConfiguration {

    let content = content()
    if #available(iOS 16.0, *), !useReusableHostingConfiguration {
        let configuration = UIHostingConfiguration {
            content
                .modifier(
                    HostingConfigurationModifier(
                        id: id,
                        isEmpty: content.isEmptyView,
                        state: HostingConfigurationState(storage: state),
                        transaction: transaction,
                        updatePhase: updatePhase
                    )
                )
        }
        .background(.clear)
        .margins(.all, 0)
        return configuration
    } else {
        return HostingConfiguration {
            content
                .modifier(
                    HostingConfigurationModifier(
                        id: id,
                        isEmpty: content.isEmptyView,
                        state: HostingConfigurationState(storage: state),
                        transaction: transaction,
                        updatePhase: updatePhase
                    )
                )
        }
    }
}

@available(iOS 14.0, *)
private struct HostingConfigurationModifier<ID: Hashable>: ViewModifier {
    var id: ID
    var isEmpty: Bool
    var state: HostingConfigurationState
    var transaction: Transaction
    var updatePhase: UpdatePhase.Value

    func body(content: Content) -> some View {
        content
            .environment(\.hostingConfigurationState, state)
            .disabled(state.isDisabled)
            .opacity(isEmpty ? 0 : 1)
            .animation(nil, value: id)
//            .transaction {
//                // Replace the default animation curve with a curve that more closely matches UICollectionView's cell
//                // resize animation
//                if $0.animation == .default {
//                    $0.animation = .spring(response: 0.3, dampingFraction: 1, blendDuration: 0)
//                }
//            }
            .transaction(transaction, value: updatePhase)
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct HostingConfiguration<
    Content: View
>: UIContentConfiguration {

    public var content: Content

    public init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    public func makeContentView() -> UIView & UIContentView {
        return HostingConfigurationContentView(configuration: self)
    }

    public func updated(for state: UIConfigurationState) -> Self {
        return self
    }
}

@available(iOS 14.0, *)
open class HostingConfigurationContentView<
    Content: View
>: HostingView<HostingConfigurationView<Content>>, UIContentView {

    public var configuration: UIContentConfiguration {
        didSet {
            let configuration = configuration as! HostingConfiguration<Content>
            content.content = configuration.content
        }
    }

    public init(configuration: HostingConfiguration<Content>) {
        self.configuration = configuration
        super.init(content: HostingConfigurationView(content: configuration.content))
        content.view = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 14.0, *)
public struct HostingConfigurationView<Content: View>: View {

    public var content: Content

    weak var view: UIView?

    public var body: some View {
        content
            .modifier(SizeObserver(view: view))
    }
}

@available(iOS 14.0, *)
private struct SizeObserver: VersionedViewModifier {
    weak var view: UIView?

    @available(iOS 16.0, *)
    func v4Body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { _ in
                view?.invalidateIntrinsicContentSize()
            }
    }

    @available(iOS 14.0, *)
    func v2Body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .hidden()
                        .onChange(of: proxy.size) { _ in
                            view?.invalidateIntrinsicContentSize()
                        }
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
