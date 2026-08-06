//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)

import SwiftUI

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct CollectionViewCoordinatorEditingConfiguration<
    Item: Equatable & Identifiable
> {
    public var isEditing: Binding<Bool>
    public var selection: Binding<Set<Item.ID>>?
    public var allowsMultipleSelectionDuringEditing: Bool
    public var shouldToggleEditingOnLongPress: Bool

    public init(
        isEditing: Binding<Bool>,
        selection: Binding<Set<Item.ID>>? = nil,
        allowsMultipleSelectionDuringEditing: Bool = false,
        shouldToggleEditingOnLongPress: Bool = false
    ) {
        self.isEditing = isEditing
        self.selection = selection
        self.allowsMultipleSelectionDuringEditing = allowsMultipleSelectionDuringEditing
        self.shouldToggleEditingOnLongPress = shouldToggleEditingOnLongPress
    }
}

#endif
