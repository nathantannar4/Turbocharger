//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A modifier that adds additional safe area padding
/// to the edges of a view.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public typealias SafeAreaPaddingModifier = Engine.SafeAreaInsetsModifier

@available(iOS, introduced: 14.0, deprecated: 17.0, renamed: "safeAreaInsets")
@available(macOS, introduced: 11.0, deprecated: 14.0, renamed: "safeAreaInsets")
@available(tvOS, introduced: 14.0, deprecated: 17.0, renamed: "safeAreaInsets")
@available(watchOS, introduced: 7.0, deprecated: 10.0, renamed: "safeAreaInsets")
@available(visionOS, unavailable)
extension View {

    /// A modifier that adds additional safe area padding
    /// to the edges of a view.
    @inlinable
    @_disfavoredOverload
    public func safeAreaPadding(_ edgeInsets: EdgeInsets) -> some View {
        modifier(SafeAreaPaddingModifier(edgeInsets))
    }

    /// A modifier that adds additional safe area padding
    /// to the edges of a view.
    @inlinable
    @_disfavoredOverload
    public func safeAreaPadding(_ length: CGFloat = 16) -> some View {
        modifier(SafeAreaPaddingModifier(length))
    }

    /// A modifier that adds additional safe area padding
    /// to the edges of a view.
    @inlinable
    @_disfavoredOverload
    public func safeAreaPadding(_ edges: Edge.Set, _ length: CGFloat = 16) -> some View {
        modifier(SafeAreaPaddingModifier(edges, length))
    }
}
