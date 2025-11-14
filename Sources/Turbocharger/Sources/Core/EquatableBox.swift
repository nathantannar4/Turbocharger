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
        return withUnsafeBytes(of: lhs.value) { lhsBytes in
            withUnsafeBytes(of: rhs.value) { rhsBytes in
                guard lhsBytes.count == rhsBytes.count else { return false }
                return lhsBytes.elementsEqual(rhsBytes)
            }
        }
    }
}

extension EquatableBox: Identifiable where Value: Identifiable {
    public var id: Value.ID { value.id }
}
