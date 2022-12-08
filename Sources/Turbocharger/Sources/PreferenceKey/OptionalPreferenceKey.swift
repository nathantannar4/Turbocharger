//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A preference key that defaults to `nil`
public protocol OptionalPreferenceKey: PreferenceKey where Value == Optional<WrappedValue> {
    associatedtype WrappedValue: Equatable
}

extension OptionalPreferenceKey {
    public var defaultValue: Value { .none }

    public static func reduce(value: inout Value, nextValue: () -> Value) {
        if value == nil {
            value = nextValue()
        }
    }
}
