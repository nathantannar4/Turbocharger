//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor @preconcurrency
public protocol CollectionViewLayout: Equatable, Sendable {

    #if os(iOS)
    associatedtype UICollectionViewLayoutType: UICollectionViewLayout
    associatedtype UICollectionViewType: UICollectionView
    associatedtype UICollectionViewCellType: UICollectionViewCell = UICollectionViewCell
    associatedtype UICollectionViewSupplementaryViewType: UICollectionReusableView = UICollectionViewCell

    @MainActor @preconcurrency func makeUICollectionViewLayout(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionViewLayoutType

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

    @MainActor @preconcurrency func shouldInvalidateLayout(
        from oldValue: Self,
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> Bool
    #endif

    typealias Context = CollectionViewLayoutContext

}

#if os(iOS)
@available(iOS 14.0, *)
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

    public func shouldInvalidateLayout(
        from oldValue: Self,
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> Bool {
        return oldValue != self
    }
}
#endif

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
public struct CollectionViewLayoutOptions {
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
public struct CollectionViewSupplementaryView: Hashable, Sendable {

    @MainActor
    public enum ID: Hashable, Sendable {
        case header
        case footer
        case custom(String)

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

    private init(
        id: ID,
        alignment: Alignment,
        offset: CGPoint = .zero,
        contentInset: EdgeInsets = .zero,
        zIndex: Int = 0
    ) {
        self.id = id
        self.alignment = alignment
        self.offset = offset
        self.contentInset = contentInset
        self.zIndex = zIndex
    }

    public var kind: String {
        id.kind
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// The `UICollectionViewLayout` should include a header
    public static let header = CollectionViewSupplementaryView.header()

    /// The `UICollectionViewLayout` should include a header
    public static func header(
        offset: CGPoint = .zero,
        contentInset: EdgeInsets = .zero,
        zIndex: Int = 2
    ) -> CollectionViewSupplementaryView {
        CollectionViewSupplementaryView(
            id: .header,
            alignment: .topLeading,
            offset: offset,
            contentInset: contentInset,
            zIndex: zIndex
        )
    }

    /// The `UICollectionViewLayout` should include a footer
    public static let footer = CollectionViewSupplementaryView.footer()

    /// The `UICollectionViewLayout` should include a footer
    public static func footer(
        offset: CGPoint = .zero,
        contentInset: EdgeInsets = .zero,
        zIndex: Int = 1
    ) -> CollectionViewSupplementaryView {
        CollectionViewSupplementaryView(
            id: .footer,
            alignment: .bottomTrailing,
            offset: offset,
            contentInset: contentInset,
            zIndex: zIndex
        )
    }

    /// The `UICollectionViewLayout` should include a custom kind
    public static func custom(
        _ id: String,
        alignment: Alignment,
        offset: CGPoint = .zero,
        contentInset: EdgeInsets = .zero,
        zIndex: Int = 0
    ) -> CollectionViewSupplementaryView {
        CollectionViewSupplementaryView(
            id: .custom(id),
            alignment: alignment,
            offset: offset,
            contentInset: contentInset,
            zIndex: zIndex
        )
    }
}
