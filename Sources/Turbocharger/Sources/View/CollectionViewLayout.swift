//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)

import UIKit
import SwiftUI
import Engine

public struct EmptyCollectionViewConfiguration: Equatable { }

@available(iOS 14.0, tvOS 14.0, *)
@MainActor @preconcurrency
public protocol CollectionViewLayout {

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

    typealias Context = CollectionViewLayoutContext
}

@available(iOS 14.0, tvOS 14.0, *)
extension CollectionViewLayout where Configuration == EmptyCollectionViewConfiguration {

    public var configuration: EmptyCollectionViewConfiguration { .init() }
}

@available(iOS 14.0, tvOS 14.0, *)
extension CollectionViewLayout {

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

@available(iOS 14.0, tvOS 14.0, *)
public protocol ComposableCollectionViewLayout: CollectionViewLayout {

    associatedtype Layout: CollectionViewLayout
    var layout: Layout { get }
}

@available(iOS 14.0, tvOS 14.0, *)
extension ComposableCollectionViewLayout {

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
}

@frozen
@available(iOS 14.0, tvOS 14.0, *)
public struct CollectionViewLayoutContext {

    public var environment: EnvironmentValues
    public var transaction: Transaction

    public init(environment: EnvironmentValues, transaction: Transaction) {
        self.environment = environment
        self.transaction = transaction
    }
}

@frozen
@available(iOS 14.0, tvOS 14.0, *)
public struct CollectionViewLayoutOptions: Equatable {

    public var safeAreaInsets: EdgeInsets?
    public var supplementaryViews: [CollectionViewSupplementaryView]

    public init(
        safeAreaInsets: EdgeInsets? = nil,
        supplementaryViews: [CollectionViewSupplementaryView] = []
    ) {
        self.safeAreaInsets = safeAreaInsets
        self.supplementaryViews = supplementaryViews
    }
}

@available(iOS 14.0, tvOS 14.0, *)
public struct CollectionViewSupplementaryView: Equatable {

    public enum ID: Hashable, ExpressibleByStringLiteral {
        case header
        case footer
        case custom(String)

        public init(stringLiteral value: String) {
            self = .custom(value)
        }

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

        @MainActor
        public var kind: String {
            switch self {
            case .header:
                return UICollectionView.elementKindSectionHeader
            case .footer:
                return UICollectionView.elementKindSectionFooter
            case .custom(let id):
                return id
            }
        }
    }

    public var id: ID
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

    @MainActor
    public var kind: String {
        id.kind
    }

    /// The `UICollectionViewLayout` should include a header
    public static var header: CollectionViewSupplementaryView { .header() }

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
    public static var footer: CollectionViewSupplementaryView { .footer() }

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

    @MainActor
    func toUIKit(
        unspecifiedDimension: NSCollectionLayoutSize
    ) -> NSCollectionLayoutBoundarySupplementaryItem {
        let supplementaryItemSize: NSCollectionLayoutSize
        if let layoutSize = layoutSize {
            supplementaryItemSize = layoutSize.toUIKit(
                replacingUnspecifiedDimensionBy: unspecifiedDimension
            )
        } else {
            supplementaryItemSize = unspecifiedDimension
        }
        let item = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: supplementaryItemSize,
            elementKind: kind,
            alignment: {
                switch alignment {
                case .top:
                    return .top
                case .topLeading:
                    return .topLeading
                case .topTrailing:
                    return .topLeading
                case .bottom:
                    return .bottom
                case .bottomLeading:
                    return .bottomLeading
                case .bottomTrailing:
                    return .bottomTrailing
                case .leading:
                    return .leading
                case .trailing:
                    return .trailing
                default:
                    return .none
                }
            }(),
            absoluteOffset: offset
        )
        item.extendsBoundary = extendsBoundary
        item.contentInsets = NSDirectionalEdgeInsets(contentInset)
        item.zIndex = zIndex
        return item
    }
}

#endif
