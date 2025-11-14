//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import Engine

import UIKit
import SwiftUI

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
    Items.Element.ID: Sendable,
    Section.ID: Sendable,
    Layout.UICollectionViewCellType: UICollectionViewCell,
    Layout.UICollectionViewSupplementaryViewType: UICollectionViewCell
{

    public var header: (Section) -> Header
    public var content: (Items.Element) -> Content
    public var footer: (Section) -> Footer
    public var supplementaryView: (CollectionViewSupplementaryView.ID, Section) -> SupplementaryView

    private var update = HostingConfigurationUpdate(animation: nil, value: 0)

    public init(
        header: @escaping (Section) -> Header,
        content: @escaping (Items.Element) -> Content,
        footer: @escaping (Section) -> Footer,
        supplementaryView: @escaping (CollectionViewSupplementaryView.ID, Section) -> SupplementaryView,
        layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        refresh: (() async -> Void)? = nil,
        reorder: ((_ from: (Int, IndexSet), _ to: (Int, Int)) -> Void)? = nil,
        layoutOptions: CollectionViewLayoutOptions
    ) {
        self.header = header
        self.content = content
        self.footer = footer
        self.supplementaryView = supplementaryView
        super.init(
            sections: sections,
            refresh: refresh,
            reorder: reorder,
            layout: layout,
            layoutOptions: layoutOptions
        )

        // Invoke the view builders to trigger SwiftUI's runtime to form a
        // dependency between any DynamicProperty that the @escaping value
        // uses.
        for section in sections {
            _ = header(section.section)
            _ = footer(section.section)

            for supplementaryViewId in layoutOptions.supplementaryViews {
                _ = supplementaryView(supplementaryViewId.id, section.section)
            }

            if let first = section.items.first {
                _ = content(first)
            }
        }
    }

    public convenience init(
        header: @escaping (Section) -> Header,
        content: @escaping (Items.Element) -> Content,
        footer: @escaping (Section) -> Footer,
        layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        refresh: (() async -> Void)? = nil,
        layoutOptions: CollectionViewLayoutOptions
    ) where SupplementaryView == EmptyView {
        self.init(
            header: header,
            content: content,
            footer: footer,
            supplementaryView: { _, _ in EmptyView() },
            layout: layout,
            sections: sections,
            refresh: refresh,
            layoutOptions: layoutOptions
        )
    }

    public convenience init(
        content: @escaping (Items.Element) -> Content,
        layout: Layout,
        sections: [CollectionViewSection<Section, Items>],
        refresh: (() async -> Void)? = nil
    ) where Header == EmptyView, Footer == EmptyView, SupplementaryView == EmptyView {
        self.init(
            header: { _ in EmptyView() },
            content: content,
            footer: { _ in EmptyView() },
            supplementaryView: { _, _ in EmptyView() },
            layout: layout,
            sections: sections,
            refresh: refresh,
            layoutOptions: .init()
        )
    }

    open override func dequeueReusableCell(
        collectionView: Layout.UICollectionViewType,
        indexPath: IndexPath,
        id: ID
    ) -> Layout.UICollectionViewCellType? {
        let cell = super.dequeueReusableCell(collectionView: collectionView, indexPath: indexPath, id: id)
        cell?.automaticallyUpdatesContentConfiguration = false
        cell?.automaticallyUpdatesBackgroundConfiguration = false
        cell?.layoutIfNeeded()
        return cell
    }

    open override func configureCell(
        _ cell: Layout.UICollectionViewCellType,
        indexPath: IndexPath,
        item: Items.Element
    ) {
        cell.contentConfiguration = makeContent(value: item)
    }

    open override func dequeueReusableSupplementaryView(
        collectionView: Layout.UICollectionViewType,
        kind: String,
        indexPath: IndexPath
    ) -> Layout.UICollectionViewSupplementaryViewType? {
        let supplementaryView = super.dequeueReusableSupplementaryView(collectionView: collectionView, kind: kind, indexPath: indexPath)
        supplementaryView?.automaticallyUpdatesContentConfiguration = false
        supplementaryView?.automaticallyUpdatesBackgroundConfiguration = false
        supplementaryView?.layoutIfNeeded()
        return supplementaryView
    }

    open override func configureSupplementaryView(
        _ supplementaryView: Layout.UICollectionViewSupplementaryViewType,
        kind: String,
        indexPath: IndexPath
    ) {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            supplementaryView.contentConfiguration = makeHeaderContent(indexPath: indexPath)
        case UICollectionView.elementKindSectionFooter:
            supplementaryView.contentConfiguration = makeFooterContent(indexPath: indexPath)
        default:
            supplementaryView.contentConfiguration = makeSupplementaryContent(kind: kind, indexPath: indexPath)
        }
    }

    open override func performUpdate(
        sections: [CollectionViewSection<Section, Items>],
        animation: Animation?,
        completion: (() -> Void)? = nil
    ) {
        update.advance(animation: animation)
        super.performUpdate(
            sections: sections,
            animation: animation,
            completion: { [weak self] in
                self?.update.animation = nil
                completion?()
            }
        )
    }

    private func makeContent(
        value: Items.Element
    ) -> UIContentConfiguration {
        makeHostingConfiguration(
            id: value.id,
            kind: .cell,
            update: update
        ) {
            content(value)
        }
    }

    private func makeHeaderContent(
        indexPath: IndexPath
    ) -> UIContentConfiguration {
        let section = sections[indexPath.section].section
        return makeHostingConfiguration(
            id: section.id,
            kind: .supplementary(UICollectionView.elementKindSectionHeader),
            update: update
        ) {
            header(section)
        }
    }

    private func makeFooterContent(
        indexPath: IndexPath
    ) -> UIContentConfiguration {
        let section = sections[indexPath.section].section
        return makeHostingConfiguration(
            id: section.id,
            kind: .supplementary(UICollectionView.elementKindSectionFooter),
            update: update
        ) {
            footer(section)
        }
    }

    private func makeSupplementaryContent(
        kind: String,
        indexPath: IndexPath
    ) -> UIContentConfiguration {
        let section = sections[indexPath.section].section
        return makeHostingConfiguration(
            id: section.id,
            kind: .supplementary(kind),
            update: update
        ) {
            supplementaryView(.custom(kind), section)
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
    kind: HostingConfigurationKind,
    update: HostingConfigurationUpdate,
    @ViewBuilder content: () -> Content
) -> UIContentConfiguration {

    let content = content()
    let isEmpty: Bool = {
        var visitor = MultiViewIsEmptyVisitor()
        content.visit(visitor: &visitor)
        return visitor.isEmpty
    }()

    if #available(iOS 16.0, *) {
        return UIHostingConfiguration {
            content
                .modifier(
                    HostingConfigurationModifier(
                        id: id,
                        isEmpty: isEmpty,
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
                        isEmpty: isEmpty,
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
    var update: HostingConfigurationUpdate

    func body(content: Content) -> some View {
        content
            .opacity(isEmpty ? 0 : 1)
            .transition(.identity)
            .id(id)
            .animation(update.animation, value: update.value)
    }
}

private enum HostingConfigurationKind {
    case supplementary(String)
    case cell
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct HostingConfigurationBackport<
    Content: View
>: UIContentConfiguration {

    var kind: HostingConfigurationKind
    var content: Content

    init(
        kind: HostingConfigurationKind,
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
        case .supplementary(let kind):
            guard
                let supplementaryView = superview as? UICollectionReusableView,
                let collectionView = supplementaryView.superview as? UICollectionView,
                let indexPath = collectionView.indexPath(forSupplementaryView: supplementaryView)
            else {
                return
            }
            ctx.invalidateSupplementaryElements(ofKind: kind, at: [indexPath])
            collectionView.collectionViewLayout.invalidateLayout(with: ctx)
            supplementaryView.layoutIfNeeded()

        case .cell:
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
        Preview()
    }

    struct Preview: View {
        struct Item: Identifiable, Equatable {
            var id = UUID().uuidString
            var value = 0
        }

        @State var items: [Item] = (0..<5).map { Item(value: $0) }
        @State var showHeader = true

        var body: some View {
            CollectionView(
                .compositional,
                items: items
            ) { item in
                Text(item.id)
                    .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                    .background(.white.opacity(0.3))
            } header: { index in
                if showHeader {
                    Text("Header")
                        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                        .background(.white)
                }
            } footer: { index in
                Text("Footer")
            }
            .background(.blue)
            .ignoresSafeArea()
            .overlay(alignment: .bottomTrailing) {
                Button("showHeader") {
                    withAnimation {
                        showHeader.toggle()
                    }
                }
                .foregroundStyle(.white)
                .padding()
            }
        }
    }
}

#endif
