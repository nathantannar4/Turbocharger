//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)

import SwiftUI

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct CollectionViewSupplementaryViewVisibility: Equatable {

    @usableFromInline
    enum Visibility: Equatable {
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

    public static var hidden: CollectionViewSupplementaryViewVisibility {
        CollectionViewSupplementaryViewVisibility(visibility: .hidden)
    }

    public static func hidden(
        in sections: IndexSet
    ) -> CollectionViewSupplementaryViewVisibility {
        CollectionViewSupplementaryViewVisibility(
            sections: sections,
            visibility: .hidden
        )
    }

    public static var visible: CollectionViewSupplementaryViewVisibility {
        CollectionViewSupplementaryViewVisibility(visibility: .visible)
    }

    public static func visible(
        in sections: IndexSet
    ) -> CollectionViewSupplementaryViewVisibility {
        CollectionViewSupplementaryViewVisibility(
            sections: sections,
            visibility: .visible
        )
    }
}

#endif
