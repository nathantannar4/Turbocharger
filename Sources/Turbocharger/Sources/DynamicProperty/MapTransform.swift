//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct MapTransform<Input, Output>: BindingTransform {

    @usableFromInline
    var keyPath: WritableKeyPath<Input, Output>

    @inlinable
    public init(keyPath: WritableKeyPath<Input, Output>) {
        self.keyPath = keyPath
    }

    public func get(_ value: Input) -> Output {
        value[keyPath: keyPath]
    }

    public func set(_ newValue: Output, oldValue: @autoclosure () -> Input, transaction: Transaction) throws -> Input {
        var copy = oldValue()
        copy[keyPath: keyPath] = newValue
        return copy
    }
}

extension Binding {
    @inlinable
    public func map<T>(_ keyPath: WritableKeyPath<Value, T>) -> Binding<T> {
        projecting(MapTransform(keyPath: keyPath))
    }
}
