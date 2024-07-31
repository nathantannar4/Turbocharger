//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A modifier that conditionally hides a view
@frozen
public struct HiddenModifier: ViewModifier {

    public var isHidden: Bool
    public var transition: AnyTransition

    @inlinable
    public init(
        isHidden: Bool,
        transition: AnyTransition = .opacity
    ) {
        self.isHidden = isHidden
        self.transition = transition
    }

    public func body(content: Content) -> some View {
        if isHidden {
            content
                .hidden()
        } else {
            content
                .transition(transition)
        }
    }
}

extension View {

    /// A modifier that conditionally hides a view
    @inlinable
    public func hidden(
        _ isHidden: Bool,
        transition: AnyTransition = .identity
    ) -> some View {
        modifier(
            HiddenModifier(
                isHidden: isHidden,
                transition: transition
            )
        )
    }
}
