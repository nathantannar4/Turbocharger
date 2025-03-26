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

    public init(
        header: @escaping (Data.Index) -> Header,
        content: @escaping (Data.Element.Element) -> Content,
        footer: @escaping (Data.Index) -> Footer,
        layout: Layout,
        data: Data,
        refresh: (() async -> Void)? = nil,
        layoutOptions: CollectionViewLayoutOptions
    ) {
        self.header = header
        self.content = content
        self.footer = footer
        super.init(data: data, refresh: refresh, layout: layout, layoutOptions: layoutOptions)
    }

    public init(
        content: @escaping (Data.Element.Element) -> Content,
        layout: Layout,
        data: Data,
        refresh: (() async -> Void)? = nil
    ) where Header == EmptyView, Footer == EmptyView {
        self.header = { _ in EmptyView() }
        self.content = content
        self.footer = { _ in EmptyView() }
        super.init(data: data, refresh: refresh, layout: layout, layoutOptions: .init())
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
            break
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
            .transaction {
                // Animate size changes in sync with cell frame changes
                if !$0.disablesAnimations, $0.animation == nil {
                    $0.animation = .spring(response: 0.4, dampingFraction: 1)
                }
            }
    }

    func v1Body(content: Content) -> some View {
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

#endif
