//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)

import UIKit
import SwiftUI
import Engine

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public enum CollectionViewLayoutElementKind: Equatable {
    case item
    case supplementaryView(CollectionViewSupplementaryView.ID)
}

@available(iOS 14.0, tvOS 14.0, *)
public protocol CollectionViewLayoutAttributes: Equatable {

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
}

@available(iOS 14.0, tvOS 14.0, *)
extension CollectionViewLayoutAttributes {

    public func initialAppearingLayoutAttributes(
        for element: CollectionViewLayoutElementKind,
        at indexPath: IndexPath,
        layout: UICollectionViewLayout,
        attributes: inout UICollectionViewLayoutAttributes
    ) {}

    public func layoutAttributes(
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
}

#endif
