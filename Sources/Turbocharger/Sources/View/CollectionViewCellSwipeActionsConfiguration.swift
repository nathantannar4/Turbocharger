//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
import SwiftUI
import Engine

@available(iOS 14.0, tvOS 14.0, *)
public protocol CollectionViewCellSwipeActionsConfiguration: Equatable {

    #if os(iOS) || os(visionOS)
    @MainActor @preconcurrency func makeConfiguration(
        indexPath: IndexPath,
        context: Context
    ) -> UISwipeActionsConfiguration
    #endif

    typealias Context = CollectionViewLayoutContext
}

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct AnyCollectionViewCellSwipeActionsConfiguration: CollectionViewCellSwipeActionsConfiguration {

    @usableFromInline
    var storage: AnyCollectionViewCellSwipeActionsConfigurationStorageBase

    @available(tvOS, unavailable)
    public init<Configuration: CollectionViewCellSwipeActionsConfiguration>(_ configuration: Configuration) {
        storage = AnyCollectionViewCellSwipeActionsConfigurationStorage(configuration)
    }

    #if os(iOS) || os(visionOS)
    public func makeConfiguration(
        indexPath: IndexPath,
        context: Context
    ) -> UISwipeActionsConfiguration {
        storage.makeConfiguration(indexPath: indexPath, context: context)
    }
    #endif

    public static func == (
        lhs: AnyCollectionViewCellSwipeActionsConfiguration,
        rhs: AnyCollectionViewCellSwipeActionsConfiguration
    ) -> Bool {
        lhs.storage.isEqual(to: rhs.storage)
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@usableFromInline
class AnyCollectionViewCellSwipeActionsConfigurationStorageBase {

    #if os(iOS) || os(visionOS)
    @MainActor @preconcurrency
    func makeConfiguration(
        indexPath: IndexPath,
        context: CollectionViewLayoutContext
    ) -> UISwipeActionsConfiguration {
        fatalError("base")
    }
    #endif

    func isEqual(to other: AnyCollectionViewCellSwipeActionsConfigurationStorageBase) -> Bool {
        fatalError("base")
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@usableFromInline
final class AnyCollectionViewCellSwipeActionsConfigurationStorage<
    Configuration: CollectionViewCellSwipeActionsConfiguration
>: AnyCollectionViewCellSwipeActionsConfigurationStorageBase {

    let configuration: Configuration

    init(_ configuration: Configuration) {
        self.configuration = configuration
    }

    #if os(iOS) || os(visionOS)
    override func makeConfiguration(
        indexPath: IndexPath,
        context: CollectionViewLayoutContext
    ) -> UISwipeActionsConfiguration {
        configuration.makeConfiguration(indexPath: indexPath, context: context)
    }
    #endif

    override func isEqual(to other: AnyCollectionViewCellSwipeActionsConfigurationStorageBase) -> Bool {
        guard let other = other as? AnyCollectionViewCellSwipeActionsConfigurationStorage<Configuration> else {
            return false
        }
        return configuration == other.configuration
    }
}

#endif
