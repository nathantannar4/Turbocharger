//
// Copyright (c) Nathan Tannar
//

import Foundation

@frozen
public struct IdentifiableBox<Value, ID: Hashable>: Identifiable {
    public var value: Value
    public var keyPath: KeyPath<Value, ID>

    public var id: ID { value[keyPath: keyPath] }

    @inlinable
    public init(_ value: Value, id keyPath: KeyPath<Value, ID>) {
        self.value = value
        self.keyPath = keyPath
    }
}

extension IdentifiableBox: Equatable where Value: Equatable { }
extension IdentifiableBox: Hashable where Value: Hashable { }
