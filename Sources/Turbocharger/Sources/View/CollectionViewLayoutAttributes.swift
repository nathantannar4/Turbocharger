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
    @MainActor @preconcurrency func initialAppearingLayoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    )

    @MainActor @preconcurrency func layoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    )

    @MainActor @preconcurrency func finalDisappearingLayoutAttributes(
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
    @MainActor @preconcurrency public func initialAppearingLayoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    ) {}

    @MainActor @preconcurrency public func finalDisappearingLayoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    ) {}
    #endif
}
