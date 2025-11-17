//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI

/// A collection wrapper for grouping items in a section
@frozen
public struct CollectionViewSection<
    Section: Equatable & Identifiable,
    Items: RandomAccessCollection
>: RandomAccessCollection where
    Items.Element: Equatable & Identifiable,
    Items.Element.ID: Sendable,
    Section.ID: Sendable
{

    public var items: Items
    public var section: Section

    public init(items: Items, section: Section) {
        self.items = items
        self.section = section
    }

    public init<
        _Items: RandomAccessCollection,
        ID: Hashable & Sendable
    >(
        items: _Items,
        id: KeyPath<_Items.Element, ID>,
        section: Int
    ) where
        _Items.Element: Equatable,
        Items == Array<IdentifiableBox<_Items.Element, ID>>,
        Section == CollectionViewSectionIndex
    {
        let items = items.map { IdentifiableBox($0, id: id) }
        self.init(items: items, section: section)
    }

    public init(items: Items, section: Int) where Section == CollectionViewSectionIndex {
        self.items = items
        self.section = CollectionViewSectionIndex(index: section)
    }

    public var id: Section.ID {
        section.id
    }

    // MARK: - RandomAccessCollection

    public typealias Index = Items.Index
    public typealias Element = Items.Element

    public var startIndex: Index {
        items.startIndex
    }

    public var endIndex: Index {
        items.endIndex
    }

    public subscript(position: Index) -> Element {
        items[position]
    }

    public func index(after i: Index) -> Index {
        items.index(after: i)
    }

    public func index(before i: Index) -> Index {
        items.index(before: i)
    }
}

extension CollectionViewSection: Equatable where Section: Equatable, Items: Equatable { }
extension CollectionViewSection: Hashable where Section: Hashable, Items: Hashable { }
extension CollectionViewSection: Sendable where Section: Sendable, Items: Sendable { }

@frozen
public struct CollectionViewSectionIndex: Hashable, Identifiable, Sendable {

    public var index: Int

    public var id: CollectionViewSectionIndex { self }

    public init(index: Int) {
        self.index = index
    }
}


#endif
