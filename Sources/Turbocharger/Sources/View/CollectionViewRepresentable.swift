//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol CollectionViewLayout: DynamicProperty {
    
    #if os(iOS)
    associatedtype UICollectionViewType: UICollectionView

    func makeUICollectionView(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionViewType

    func updateUICollectionView(
        _ collectionView: UICollectionViewType,
        context: Context
    )

    func updateUICollectionViewCell(
        _ collectionView: UICollectionViewType,
        cell: UICollectionViewCell,
        kind: HostingConfigurationKind,
        indexPath: IndexPath
    )
    #endif

    typealias Context = CollectionViewLayoutContext

}

#if os(iOS)
@available(iOS 14.0, *)
extension CollectionViewLayout {
    public func updateUICollectionViewCell(
        _ collectionView: UICollectionViewType,
        cell: UICollectionViewCell,
        kind: HostingConfigurationKind,
        indexPath: IndexPath
    ) { }
}
#endif

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct CollectionViewLayoutContext {
    public var environment: EnvironmentValues
    public var transaction: Transaction
}

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

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct CollectionViewListLayout: CollectionViewLayout {

    @inlinable
    public init() { }

    #if os(iOS)
    public func makeUICollectionView(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionView {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.headerMode = options.contains(.header) ? .supplementary : .none
        configuration.footerMode = options.contains(.footer) ? .supplementary : .none
        configuration.showsSeparators = false
        configuration.backgroundColor = .clear
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let uiCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        uiCollectionView.clipsToBounds = false
        uiCollectionView.keyboardDismissMode = .interactive
        return uiCollectionView
    }

    public func updateUICollectionView(
        _ collectionView: UICollectionView,
        context: Context
    ) { }
    #endif
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionViewLayout where Self == CollectionViewListLayout {
    public static var list: CollectionViewListLayout { .init() }
}
