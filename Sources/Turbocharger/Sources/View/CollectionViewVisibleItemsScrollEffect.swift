//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)

import UIKit
import SwiftUI
import Engine

@available(iOS 14.0, tvOS 14.0, *)
public protocol CollectionViewVisibleItemsScrollEffect: Equatable {

    @MainActor @preconcurrency func onScroll(
        visibleItem: [NSCollectionLayoutVisibleItem],
        contentOffset: CGPoint,
        environment: NSCollectionLayoutEnvironment,
        context: Context
    )

    typealias Context = CollectionViewLayoutContext
}

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct AnyCollectionViewVisibleItemsScrollEffect: CollectionViewVisibleItemsScrollEffect {

    @usableFromInline
    var storage: AnyCollectionViewVisibleItemsScrollEffectStorageBase

    public init<Configuration: CollectionViewVisibleItemsScrollEffect>(_ configuration: Configuration) {
        storage = AnyCollectionViewVisibleItemsScrollEffectStorage(configuration)
    }

    public func onScroll(
        visibleItem: [NSCollectionLayoutVisibleItem],
        contentOffset: CGPoint,
        environment: NSCollectionLayoutEnvironment,
        context: Context
    ) {
        storage.onScroll(
            visibleItem: visibleItem,
            contentOffset: contentOffset,
            environment: environment,
            context: context
        )
    }

    public static func == (
        lhs: AnyCollectionViewVisibleItemsScrollEffect,
        rhs: AnyCollectionViewVisibleItemsScrollEffect
    ) -> Bool {
        lhs.storage.isEqual(to: rhs.storage)
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@usableFromInline
class AnyCollectionViewVisibleItemsScrollEffectStorageBase {

    @MainActor @preconcurrency
    func onScroll(
        visibleItem: [NSCollectionLayoutVisibleItem],
        contentOffset: CGPoint,
        environment: NSCollectionLayoutEnvironment,
        context: Context
    ) {
        fatalError("base")
    }

    func isEqual(to other: AnyCollectionViewVisibleItemsScrollEffectStorageBase) -> Bool {
        fatalError("base")
    }

    typealias Context = CollectionViewLayoutContext
}

@available(iOS 14.0, tvOS 14.0, *)
@usableFromInline
final class AnyCollectionViewVisibleItemsScrollEffectStorage<
    Configuration: CollectionViewVisibleItemsScrollEffect
>: AnyCollectionViewVisibleItemsScrollEffectStorageBase {

    let configuration: Configuration

    init(_ configuration: Configuration) {
        self.configuration = configuration
    }

    override func onScroll(
        visibleItem: [NSCollectionLayoutVisibleItem],
        contentOffset: CGPoint,
        environment: NSCollectionLayoutEnvironment,
        context: Context
    ) {
        configuration.onScroll(
            visibleItem: visibleItem,
            contentOffset: contentOffset,
            environment: environment,
            context: context
        )
    }

    override func isEqual(to other: AnyCollectionViewVisibleItemsScrollEffectStorageBase) -> Bool {
        guard let other = other as? AnyCollectionViewVisibleItemsScrollEffectStorage<Configuration> else {
            return false
        }
        return configuration == other.configuration
    }
}

#endif
