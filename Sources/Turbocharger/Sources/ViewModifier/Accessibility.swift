//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

extension View {
    /// Disables accessibility elements from being generated, even when an assistive technology is running
    @inlinable
    public func accessibilityDisabled() -> some View {
        environment(\.accessibilityEnabled, false)
    }
}

@frozen
public struct AccessibilityShowsLargeContentViewModifierIfAvailable: VersionedViewModifier {
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func v3Body(content: Content) -> some View {
        content
            .accessibilityShowsLargeContentViewer()
    }
}

@frozen
public struct AccessibilityLargeContentViewModifierIfAvailable<Label: View>: VersionedViewModifier {

    @usableFromInline
    var label: Label

    @inlinable
    public init(@ViewBuilder label: () -> Label) {
        self.label = label()
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func v3Body(content: Content) -> some View {
        content
            .accessibilityShowsLargeContentViewer { label }
    }
}

extension View {
    public func accessibilityShowsLargeContentViewerIfAvailable() -> some View {
        modifier(AccessibilityShowsLargeContentViewModifierIfAvailable())
    }

    @inlinable
    public func accessibilityLargeContentViewerIfAvailable<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        modifier(AccessibilityLargeContentViewModifierIfAvailable(label: label))
    }
}

extension View {
    /// Optionally uses the specified string to identify the view.
    ///
    /// Use this value for testing. It isn't visible to the user.
    @inlinable
    public func accessibilityIdentifier(_ identifier: String?) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        guard let identifier = identifier else {
            return accessibility(addTraits: [])
        }
        return accessibility(identifier: identifier)
    }

    /// Optionally adds a label to the view that describes its contents.
    ///
    /// Use this method to provide an accessibility label for a view that doesn't display text, like an icon.
    /// For example, you could use this method to label a button that plays music with the text "Play".
    /// Don't include text in the label that repeats information that users already have. For example,
    /// don't use the label "Play button" because a button already has a trait that identifies it as a button.
    @_disfavoredOverload
    @inlinable
    public func accessibilityLabel<S: StringProtocol>(_ label: S?) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        guard let label = label else {
            return accessibility(addTraits: [])
        }
        return accessibility(label: Text(label))
    }

    /// Optionally adds a textual description of the value that the view contains.
    ///
    /// Use this method to describe the value represented by a view, but only if that's different than the
    /// view's label. For example, for a slider that you label as "Volume" using accessibility(label:),
    /// you can provide the current volume setting, like "60%", using accessibility(value:).
    @_disfavoredOverload
    @inlinable
    public func accessibilityValue<S: StringProtocol>(_ value: S?) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        guard let value = value else {
            return accessibility(addTraits: [])
        }
        return accessibility(value: Text(value))
    }

    /// Optionally adds an accessibility action to the view. Actions allow assistive technologies,
    /// such as the VoiceOver, to interact with the view by invoking the action.
    ///
    /// For example, this is how a `.default` action to compose
    /// a new email could be added to a view.
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .accessibilityAction {
    ///                 // Handle action
    ///             }
    ///     }
    ///
    @inlinable
    public func accessibilityAction(named name: LocalizedStringKey?, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        guard let name = name else {
            return accessibility(addTraits: [])
        }
        return accessibilityAction(AccessibilityActionKind(named: Text(name)), handler)
    }

    /// Optionally adds an accessibility action to the view. Actions allow assistive technologies,
    /// such as the VoiceOver, to interact with the view by invoking the action.
    ///
    /// For example, this is how a `.default` action to compose
    /// a new email could be added to a view.
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .accessibilityAction {
    ///                 // Handle action
    ///             }
    ///     }
    ///
    @_disfavoredOverload
    @inlinable
    public func accessibilityAction<S: StringProtocol>(named name: S?, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        guard let name = name else {
            return accessibility(addTraits: [])
        }
        return accessibilityAction(AccessibilityActionKind(named: Text(name)), handler)
    }
}

extension ModifiedContent where Modifier == AccessibilityAttachmentModifier {
    /// Optionally uses the specified string to identify the view.
    ///
    /// Use this value for testing. It isn't visible to the user.
    @inlinable
    public func accessibilityIdentifier(_ identifier: String?) -> ModifiedContent {
        guard let identifier = identifier else {
            return accessibility(addTraits: [])
        }
        return accessibility(identifier: identifier)
    }

    /// Optionally adds a label to the view that describes its contents.
    ///
    /// Use this method to provide an accessibility label for a view that doesn't display text, like an icon.
    /// For example, you could use this method to label a button that plays music with the text "Play".
    /// Don't include text in the label that repeats information that users already have. For example,
    /// don't use the label "Play button" because a button already has a trait that identifies it as a button.
    @_disfavoredOverload
    @inlinable
    public func accessibilityLabel<S: StringProtocol>(_ label: S?) -> ModifiedContent {
        guard let label = label else {
            return accessibility(addTraits: [])
        }
        return accessibility(label: Text(label))
    }

    /// Optionally adds a textual description of the value that the view contains.
    ///
    /// Use this method to describe the value represented by a view, but only if that's different than the
    /// view's label. For example, for a slider that you label as "Volume" using accessibility(label:),
    /// you can provide the current volume setting, like "60%", using accessibility(value:).
    @_disfavoredOverload
    @inlinable
    public func accessibilityValue<S: StringProtocol>(_ value: S?) -> ModifiedContent {
        guard let value = value else {
            return accessibility(addTraits: [])
        }
        return accessibility(value: Text(value))
    }

    /// Optionally adds an accessibility action to the view. Actions allow assistive technologies,
    /// such as the VoiceOver, to interact with the view by invoking the action.
    ///
    /// For example, this is how a `.default` action to compose
    /// a new email could be added to a view.
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .accessibilityAction {
    ///                 // Handle action
    ///             }
    ///     }
    ///
    @inlinable
    public func accessibilityAction(named name: LocalizedStringKey?, _ handler: @escaping () -> Void) -> ModifiedContent {
        guard let name = name else {
            return accessibility(addTraits: [])
        }
        return accessibilityAction(AccessibilityActionKind(named: Text(name)), handler)
    }

    /// Optionally adds an accessibility action to the view. Actions allow assistive technologies,
    /// such as the VoiceOver, to interact with the view by invoking the action.
    ///
    /// For example, this is how a `.default` action to compose
    /// a new email could be added to a view.
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .accessibilityAction {
    ///                 // Handle action
    ///             }
    ///     }
    ///
    @_disfavoredOverload
    @inlinable
    public func accessibilityAction<S: StringProtocol>(named name: S?, _ handler: @escaping () -> Void) -> ModifiedContent {
        guard let name = name else {
            return accessibility(addTraits: [])
        }
        return accessibilityAction(AccessibilityActionKind(named: Text(name)), handler)
    }
}
