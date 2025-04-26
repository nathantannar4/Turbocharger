//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

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
    Data: RandomAccessCollection
>: CollectionViewCoordinator<Layout, Data> where
    Data.Element: RandomAccessCollection,
    Data.Index: Hashable,
    Data.Element.Element: Equatable & Identifiable,
    Layout.UICollectionViewCellType == UICollectionViewCell,
    Layout.UICollectionViewSupplementaryViewType == UICollectionViewCell
{

    public var header: (Data.Index) -> Header
    public var content: (Data.Element.Element) -> Content
    public var footer: (Data.Index) -> Footer
    public var supplementaryView: (CollectionViewSupplementaryView.ID, Data.Index) -> SupplementaryView

    public init(
        header: @escaping (Data.Index) -> Header,
        content: @escaping (Data.Element.Element) -> Content,
        footer: @escaping (Data.Index) -> Footer,
        supplementaryView: @escaping (CollectionViewSupplementaryView.ID, Data.Index) -> SupplementaryView,
        layout: Layout,
        data: Data,
        refresh: (() async -> Void)? = nil,
        layoutOptions: CollectionViewLayoutOptions
    ) {
        self.header = header
        self.content = content
        self.footer = footer
        self.supplementaryView = supplementaryView
        super.init(data: data, refresh: refresh, layout: layout, layoutOptions: layoutOptions)
    }

    public convenience init(
        header: @escaping (Data.Index) -> Header,
        content: @escaping (Data.Element.Element) -> Content,
        footer: @escaping (Data.Index) -> Footer,
        layout: Layout,
        data: Data,
        refresh: (() async -> Void)? = nil,
        layoutOptions: CollectionViewLayoutOptions
    ) where SupplementaryView == EmptyView {
        self.init(
            header: header,
            content: content,
            footer: footer,
            supplementaryView: { _, _ in EmptyView() },
            layout: layout,
            data: data,
            refresh: refresh,
            layoutOptions: layoutOptions
        )
    }

    public convenience init(
        content: @escaping (Data.Element.Element) -> Content,
        layout: Layout,
        data: Data,
        refresh: (() async -> Void)? = nil
    ) where Header == EmptyView, Footer == EmptyView, SupplementaryView == EmptyView {
        self.init(
            header: { _ in EmptyView() },
            content: content,
            footer: { _ in EmptyView() },
            supplementaryView: { _, _ in EmptyView() },
            layout: layout,
            data: data,
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
        return cell
    }

    open override func configureCell(
        _ cell: Layout.UICollectionViewCellType,
        indexPath: IndexPath,
        item: Data.Element.Element
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

    private func makeContent(
        value: Data.Element.Element
    ) -> UIContentConfiguration {
        makeHostingConfiguration(
            id: value.id,
            kind: .cell
        ) {
            content(value)
        }
    }

    private func makeHeaderContent(
        indexPath: IndexPath
    ) -> UIContentConfiguration {
        let section = data.index(data.startIndex, offsetBy: indexPath.section)
        return makeHostingConfiguration(
            id: section,
            kind: .supplementary(UICollectionView.elementKindSectionHeader)
        ) {
            header(section)
        }
    }

    private func makeFooterContent(
        indexPath: IndexPath
    ) -> UIContentConfiguration {
        let section = data.index(data.startIndex, offsetBy: indexPath.section)
        return makeHostingConfiguration(
            id: section,
            kind: .supplementary(UICollectionView.elementKindSectionFooter)
        ) {
            footer(section)
        }
    }

    private func makeSupplementaryContent(
        kind: String,
        indexPath: IndexPath
    ) -> UIContentConfiguration {
        let section = data.index(data.startIndex, offsetBy: indexPath.section)
        return makeHostingConfiguration(
            id: section,
            kind: .supplementary(kind)
        ) {
            supplementaryView(.custom(kind), section)
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

    func body(content: Content) -> some View {
        content
            .transition(.identity)
            .id(id)
            .transaction {
                // Animate size changes in sync with cell frame changes
                if !$0.disablesAnimations, $0.animation == nil {
                    $0.animation = .spring(response: 0.4, dampingFraction: 1)
                }
            }
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

#endif
