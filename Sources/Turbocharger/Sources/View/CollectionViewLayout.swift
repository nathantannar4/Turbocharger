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
public protocol CollectionViewLayout {
    
    #if os(iOS)
    associatedtype UICollectionViewType: UICollectionView
    associatedtype UICollectionViewCellType: UICollectionViewCell = UICollectionViewCell
    associatedtype UICollectionViewSupplementaryViewType: UICollectionReusableView = UICollectionViewCell

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
public struct CollectionViewLayoutOptions: OptionSet {
    public var rawValue: UInt8
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    /// The `UICollectionViewLayout` should include a header
    public static let header = CollectionViewLayoutOptions(rawValue: 1 << 0)

    /// The `UICollectionViewLayout` should include a footer
    public static let footer = CollectionViewLayoutOptions(rawValue: 1 << 1)
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CollectionViewLayoutOptionsKey: EnvironmentKey {
    static let defaultValue = CollectionViewLayoutOptions()
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension EnvironmentValues {
    public var collectionViewLayoutOptions: CollectionViewLayoutOptions {
        get { self[CollectionViewLayoutOptionsKey.self] }
        set { self[CollectionViewLayoutOptionsKey.self] = newValue }
    }
}
