//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct CollectionViewSupplementaryViewVisibility: Equatable, Sendable {

    @usableFromInline
    enum Visibility: Equatable, Sendable {
        case visible
        case hidden
    }

    var sections: IndexSet?
    var visibility: Visibility

    public func isVisible(in section: Int) -> Bool {
        if sections?.contains(section) ?? true {
            return visibility == .visible
        }
        return visibility != .visible
    }

    @MainActor
    public static func automatic<Content: View>(
        _ supplementaryView: Content
    ) -> CollectionViewSupplementaryViewVisibility {
        let isEmpty = supplementaryView.isEmptyView
        return CollectionViewSupplementaryViewVisibility(
            visibility: isEmpty ? .hidden : .visible
        )
    }

    public static let hidden = CollectionViewSupplementaryViewVisibility(
        visibility: .hidden
    )

    public static func hidden(
        in sections: IndexSet
    ) -> CollectionViewSupplementaryViewVisibility {
        CollectionViewSupplementaryViewVisibility(
            sections: sections,
            visibility: .hidden
        )
    }

    public static let visible = CollectionViewSupplementaryViewVisibility(
        visibility: .visible
    )

    public static func visible(
        in sections: IndexSet
    ) -> CollectionViewSupplementaryViewVisibility {
        CollectionViewSupplementaryViewVisibility(
            sections: sections,
            visibility: .visible
        )
    }
}
