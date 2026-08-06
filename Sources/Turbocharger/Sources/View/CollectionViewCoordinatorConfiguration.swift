//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)

import UIKit
import SwiftUI
import Engine

@available(iOS 14.0, tvOS 14.0, *)
public protocol CollectionViewCoordinatorConfiguration<Item> {

    associatedtype Item: Equatable & Identifiable

    associatedtype ReuseIdentifier: Hashable

    static func reuseIdentifier(for item: Item) -> ReuseIdentifier

    static var reuseIdentifiers: Set<ReuseIdentifier> { get }
}

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct CollectionViewCoordinatorDefaultConfiguration<
    Item: Equatable & Identifiable
>: CollectionViewCoordinatorConfiguration<Item> {

    public struct ReuseIdentifier: Hashable { }

    @inlinable
    public init() { }

    public static func reuseIdentifier(for item: Item) -> ReuseIdentifier {
        return ReuseIdentifier()
    }

    public static var reuseIdentifiers: Set<ReuseIdentifier> { [ReuseIdentifier()] }
}

#endif
