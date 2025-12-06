//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

public struct EmptyCollectionViewConfiguration: Equatable { }

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor @preconcurrency
public protocol CollectionViewLayout: Sendable {

    #if os(iOS)
    associatedtype UICollectionViewLayoutType: UICollectionViewLayout
    associatedtype UICollectionViewType: UICollectionView
    associatedtype UICollectionViewCellType: UICollectionViewCell = UICollectionViewCell
    associatedtype UICollectionViewSupplementaryViewType: UICollectionReusableView = UICollectionViewCell

    /// When the configuration changes, the layout will be invalidated and updated
    associatedtype Configuration: Equatable = EmptyCollectionViewConfiguration
    var configuration: Configuration { get }

    @MainActor @preconcurrency func makeUICollectionViewLayout(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionViewLayoutType

    @MainActor @preconcurrency func updateUICollectionViewLayout(
        _ collectionViewLayout: UICollectionViewLayoutType,
        context: Context,
        options: CollectionViewLayoutOptions
    )
    
    @MainActor @preconcurrency func makeUICollectionView(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionViewType

    @MainActor @preconcurrency func updateUICollectionView(
        _ collectionView: UICollectionViewType,
        context: Context
    )

    @MainActor @preconcurrency func updateUICollectionViewCell(
        _ collectionView: UICollectionViewType,
        cell: UICollectionViewCellType,
        indexPath: IndexPath,
        context: Context
    )

    @MainActor @preconcurrency func updateUICollectionViewSupplementaryView(
        _ collectionView: UICollectionViewType,
        supplementaryView: UICollectionViewSupplementaryViewType,
        kind: String,
        indexPath: IndexPath,
        context: Context
    )

    @MainActor @preconcurrency func overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: ProposedSize,
        collectionView: UICollectionViewType
    )
    #endif

    typealias Context = CollectionViewLayoutContext
}

#if os(iOS)
@available(iOS 14.0, *)
extension CollectionViewLayout where Configuration == EmptyCollectionViewConfiguration {

    public var configuration: EmptyCollectionViewConfiguration { .init() }
}

@available(iOS 14.0, *)
extension CollectionViewLayout {

    public func updateUICollectionViewLayout(
        _ collectionViewLayout: UICollectionViewLayoutType,
        context: Context,
        options: CollectionViewLayoutOptions
    ) {
        let layout = makeUICollectionViewLayout(
            context: context,
            options: options
        )
        let collectionView = collectionViewLayout.collectionView
        collectionView?.setCollectionViewLayout(
            layout,
            animated: context.transaction.isAnimated
        )
    }

    public func updateUICollectionViewCell(
        _ collectionView: UICollectionViewType,
        cell: UICollectionViewCellType,
        indexPath: IndexPath,
        context: Context
    ) { }

    public func updateUICollectionViewSupplementaryView(
        _ collectionView: UICollectionViewType,
        supplementaryView: UICollectionViewSupplementaryViewType,
        kind: String,
        indexPath: IndexPath,
        context: Context
    ) { }

    public func overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: ProposedSize,
        collectionView: UICollectionViewType
    ) { }
}
#endif

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor @preconcurrency
public protocol ComposableCollectionViewLayout: CollectionViewLayout {

    associatedtype Layout: CollectionViewLayout
    var layout: Layout { get }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension ComposableCollectionViewLayout {

    #if os(iOS)
    public var configuration: Layout.Configuration {
        layout.configuration
    }

    public func makeUICollectionViewLayout(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> Layout.UICollectionViewLayoutType {
        layout.makeUICollectionViewLayout(
            context: context,
            options: options
        )
    }

    public func updateUICollectionViewLayout(
        _ collectionViewLayout: Layout.UICollectionViewLayoutType,
        context: Context,
        options: CollectionViewLayoutOptions
    ) {
        layout.updateUICollectionViewLayout(
            collectionViewLayout,
            context: context,
            options: options
        )
    }

    public func makeUICollectionView(
        context: CollectionViewLayoutContext,
        options: CollectionViewLayoutOptions
    ) -> Layout.UICollectionViewType {
        layout.makeUICollectionView(
            context: context,
            options: options
        )
    }

    public func updateUICollectionView(
        _ collectionView: Layout.UICollectionViewType,
        context: Context
    ) {
        layout.updateUICollectionView(
            collectionView,
            context: context
        )
    }

    public func updateUICollectionViewCell(
        _ collectionView: Layout.UICollectionViewType,
        cell: Layout.UICollectionViewCellType,
        indexPath: IndexPath,
        context: Context
    ) {
        layout.updateUICollectionViewCell(
            collectionView,
            cell: cell,
            indexPath: indexPath,
            context: context
        )
    }

    public func updateUICollectionViewSupplementaryView(
        _ collectionView: Layout.UICollectionViewType,
        supplementaryView: Layout.UICollectionViewSupplementaryViewType,
        kind: String,
        indexPath: IndexPath,
        context: Context
    ) {
        layout.updateUICollectionViewSupplementaryView(
            collectionView,
            supplementaryView: supplementaryView,
            kind: kind,
            indexPath: indexPath,
            context: context
        )
    }

    public func overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: ProposedSize,
        collectionView: Layout.UICollectionViewType
    ) {
        layout.overrideSizeThatFits(
            &size,
            in: proposedSize,
            collectionView: collectionView
        )
    }
    #endif
}

@frozen
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct CollectionViewLayoutContext {
    public var environment: EnvironmentValues
    public var transaction: Transaction
}

@frozen
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct CollectionViewLayoutOptions: Equatable {
    public var supplementaryViews: [CollectionViewSupplementaryView]

    public init(
        supplementaryViews: [CollectionViewSupplementaryView] = []
    ) {
        self.supplementaryViews = supplementaryViews
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
public struct CollectionViewSupplementaryView: Equatable, Sendable {

    public enum ID: Hashable, Sendable, ExpressibleByStringLiteral {
        case header
        case footer
        case custom(String)

        public init(stringLiteral value: String) {
            self = .custom(value)
        }

        #if os(iOS)
        init(_ kind: String) {
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                self = .header
            case UICollectionView.elementKindSectionFooter:
                self = .footer
            default:
                self = .custom(kind)
            }
        }
        #endif

        @MainActor
        public var kind: String {
            #if os(iOS)
            switch self {
            case .header:
                return UICollectionView.elementKindSectionHeader
            case .footer:
                return UICollectionView.elementKindSectionFooter
            case .custom(let id):
                return id
            }
            #else
            fatalError("unreachable")
            #endif
        }
    }

    public nonisolated var id: ID
    public var alignment: Alignment
    public var offset: CGPoint
    public var contentInset: EdgeInsets
    public var zIndex: Int
    public var extendsBoundary: Bool
    public var layoutSize: CollectionViewCompositionalLayoutSize?

    private init(
        id: ID,
        alignment: Alignment,
        offset: CGPoint = .zero,
        contentInset: EdgeInsets = .zero,
        zIndex: Int = 0,
        extendsBoundary: Bool = true,
        layoutSize: CollectionViewCompositionalLayoutSize? = nil
    ) {
        self.id = id
        self.alignment = alignment
        self.offset = offset
        self.contentInset = contentInset
        self.zIndex = zIndex
        self.extendsBoundary = extendsBoundary
        self.layoutSize = layoutSize
    }

    public var kind: String {
        id.kind
    }

    /// The `UICollectionViewLayout` should include a header
    public static let header = CollectionViewSupplementaryView.header()

    /// The `UICollectionViewLayout` should include a header
    public static func header(
        offset: CGPoint = .zero,
        contentInset: EdgeInsets = .zero,
        zIndex: Int = 2,
        layoutSize: CollectionViewCompositionalLayoutSize? = nil
    ) -> CollectionViewSupplementaryView {
        CollectionViewSupplementaryView(
            id: .header,
            alignment: .topLeading,
            offset: offset,
            contentInset: contentInset,
            zIndex: zIndex,
            layoutSize: layoutSize
        )
    }

    /// The `UICollectionViewLayout` should include a footer
    public static let footer = CollectionViewSupplementaryView.footer()

    /// The `UICollectionViewLayout` should include a footer
    public static func footer(
        offset: CGPoint = .zero,
        contentInset: EdgeInsets = .zero,
        zIndex: Int = 1,
        layoutSize: CollectionViewCompositionalLayoutSize? = nil
    ) -> CollectionViewSupplementaryView {
        CollectionViewSupplementaryView(
            id: .footer,
            alignment: .bottomTrailing,
            offset: offset,
            contentInset: contentInset,
            zIndex: zIndex,
            layoutSize: layoutSize
        )
    }

    /// The `UICollectionViewLayout` should include a custom kind
    public static func custom(
        _ id: String,
        alignment: Alignment,
        offset: CGPoint = .zero,
        contentInset: EdgeInsets = .zero,
        zIndex: Int = 0,
        extendsBoundary: Bool = true,
        layoutSize: CollectionViewCompositionalLayoutSize? = nil
    ) -> CollectionViewSupplementaryView {
        CollectionViewSupplementaryView(
            id: .custom(id),
            alignment: alignment,
            offset: offset,
            contentInset: contentInset,
            zIndex: zIndex,
            extendsBoundary: extendsBoundary,
            layoutSize: layoutSize
        )
    }
}
