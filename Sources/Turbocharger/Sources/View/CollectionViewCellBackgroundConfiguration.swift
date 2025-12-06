//
// Copyright (c) Nathan Tannar
//

#if os(iOS)
import UIKit
#endif

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol CollectionViewBackgroundConfiguration: Equatable, Sendable {

    #if os(iOS)
    func makeConfiguration(
        for kind: CollectionViewLayoutElementKind,
        state: UICellConfigurationState
    ) -> UIBackgroundConfiguration
    #endif
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct AnyCollectionViewBackgroundConfiguration: CollectionViewBackgroundConfiguration {

    @usableFromInline
    var storage: AnyCollectionViewBackgroundConfigurationStorageBase

    @inlinable
    public init<
        Configuration: CollectionViewBackgroundConfiguration
    >(
        _ configuration: Configuration
    ) {
        storage = AnyCollectionViewBackgroundConfigurationStorage(configuration)
    }

    #if os(iOS)
    public func makeConfiguration(
        for kind: CollectionViewLayoutElementKind,
        state: UICellConfigurationState
    ) -> UIBackgroundConfiguration {
        storage.makeConfiguration(for: kind, state: state)
    }
    #endif

    public static func == (
        lhs: AnyCollectionViewBackgroundConfiguration,
        rhs: AnyCollectionViewBackgroundConfiguration
    ) -> Bool {
        return lhs.storage.isEqual(to: rhs.storage)
    }

}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@usableFromInline
class AnyCollectionViewBackgroundConfigurationStorageBase: @unchecked Sendable {

    #if os(iOS)
    func makeConfiguration(
        for kind: CollectionViewLayoutElementKind,
        state: UICellConfigurationState
    ) -> UIBackgroundConfiguration {
        fatalError("base")
    }
    #endif

    func isEqual(
        to other: AnyCollectionViewBackgroundConfigurationStorageBase
    ) -> Bool {
        fatalError("base")
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@usableFromInline
final class AnyCollectionViewBackgroundConfigurationStorage<
    Configuration: CollectionViewBackgroundConfiguration
>: AnyCollectionViewBackgroundConfigurationStorageBase, @unchecked Sendable {

    var configuration: Configuration

    @usableFromInline
    init(_ configuration: Configuration) {
        self.configuration = configuration
    }

    #if os(iOS)
    override func makeConfiguration(
        for kind: CollectionViewLayoutElementKind,
        state: UICellConfigurationState
    ) -> UIBackgroundConfiguration {
        configuration.makeConfiguration(for: kind, state: state)
    }
    #endif

    override func isEqual(
        to other: AnyCollectionViewBackgroundConfigurationStorageBase
    ) -> Bool {
        guard
            let other = other as? AnyCollectionViewBackgroundConfigurationStorage<Configuration>
        else {
            return false
        }
        return configuration == other.configuration
    }
}
