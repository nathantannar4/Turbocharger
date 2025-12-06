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
