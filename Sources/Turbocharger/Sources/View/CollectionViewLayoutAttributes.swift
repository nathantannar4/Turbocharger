//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public enum CollectionViewLayoutElementKind: Equatable, Sendable {
    case item
    case supplementaryView(CollectionViewSupplementaryView.ID)
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol CollectionViewLayoutAttributes: Equatable, Sendable {

    #if os(iOS)
    func initialAppearingLayoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    )

    func layoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    )

    func finalDisappearingLayoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    )
    #endif
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionViewLayoutAttributes {

    #if os(iOS)
    public func initialAppearingLayoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    ) {}

    public func finalDisappearingLayoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    ) {}
    #endif
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct AnyCollectionViewLayoutAttributes: CollectionViewLayoutAttributes {

    @usableFromInline
    var storage: AnyCollectionViewLayoutAttributesStorageBase

    @inlinable
    public init<Attributes: CollectionViewLayoutAttributes>(
        _ attributes: Attributes
    ) {
        storage = AnyCollectionViewLayoutAttributesStorage(attributes)
    }

    #if os(iOS)
    public func initialAppearingLayoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    ) {
        storage.initialAppearingLayoutAttributes(
            for: element,
            at: indexPath,
            layout: layout,
            attributes: &attributes
        )
    }

    public func layoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    ) {
        storage.layoutAttributes(
            for: element,
            at: indexPath,
            layout: layout,
            attributes: &attributes
        )
    }

    public func finalDisappearingLayoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    ) {
        storage.finalDisappearingLayoutAttributes(
            for: element,
            at: indexPath,
            layout: layout,
            attributes: &attributes
        )
    }
    #endif

    public static func == (
        lhs: AnyCollectionViewLayoutAttributes,
        rhs: AnyCollectionViewLayoutAttributes
    ) -> Bool {
        return lhs.storage.isEqual(to: rhs.storage)
    }

}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@usableFromInline
class AnyCollectionViewLayoutAttributesStorageBase: @unchecked Sendable {

    #if os(iOS)
    func initialAppearingLayoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    ) {
        fatalError("base")
    }

    func layoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    ) {
        fatalError("base")
    }

    func finalDisappearingLayoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    ) {
        fatalError("base")
    }
    #endif

    func isEqual(
        to other: AnyCollectionViewLayoutAttributesStorageBase
    ) -> Bool {
        fatalError("base")
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@usableFromInline
final class AnyCollectionViewLayoutAttributesStorage<
    Attributes: CollectionViewLayoutAttributes
>: AnyCollectionViewLayoutAttributesStorageBase, @unchecked Sendable {

    var layoutAttributes: Attributes

    @usableFromInline
    init(
        _ layoutAttributes: Attributes
    ) {
        self.layoutAttributes = layoutAttributes
    }

    #if os(iOS)
    override func initialAppearingLayoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    ) {
        layoutAttributes.initialAppearingLayoutAttributes(
            for: element,
            at: indexPath,
            layout: layout,
            attributes: &attributes
        )
    }

    override func layoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    ) {
        layoutAttributes.layoutAttributes(
            for: element,
            at: indexPath,
            layout: layout,
            attributes: &attributes
        )
    }

    override func finalDisappearingLayoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    ) {
        layoutAttributes.finalDisappearingLayoutAttributes(
            for: element,
            at: indexPath,
            layout: layout,
            attributes: &attributes
        )
    }
    #endif

    override func isEqual(
        to other: AnyCollectionViewLayoutAttributesStorageBase
    ) -> Bool {
        guard
            let other = other as? AnyCollectionViewLayoutAttributesStorage<Attributes>
        else {
            return false
        }
        return layoutAttributes == other.layoutAttributes
    }
}
