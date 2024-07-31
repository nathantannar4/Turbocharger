//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@frozen
public struct OnAppearAndChangeModifier<
    Value: Equatable
>: VersionedViewModifier {

    public var value: Value
    public var action: (Value) -> Void

    @inlinable
    public init(value: Value, action: @escaping (Value) -> Void) {
        self.value = value
        self.action = action
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    public func v5Body(content: Content) -> some View {
        content
            .onChange(of: value, initial: true) { _, newValue in
                action(newValue)
            }
    }

    #if !os(visionOS)
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func v2Body(content: Content) -> some View {
        content
            .onAppear { action(value) }
            .onChange(of: value, perform: action)
    }
    #endif
}

extension View {

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func onAppearAndChange<V: Equatable>(
        of value: V,
        perform action: @escaping (V) -> Void
    ) -> some View {
        modifier(OnAppearAndChangeModifier(value: value, action: action))
    }
}
