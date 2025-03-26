//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct EquatableBox<Value>: Equatable {
    public var value: Value

    @inlinable
    public init(_ value: Value) {
        self.value = value
    }

    public static func == (lhs: EquatableBox<Value>, rhs: EquatableBox<Value>) -> Bool {
        return false
    }
}

extension EquatableBox: Identifiable where Value: Identifiable {
    public var id: Value.ID { value.id }
}
