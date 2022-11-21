//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import os.log

public protocol BindingTransform {
    associatedtype Input
    associatedtype Output

    func get(_ value: Input) -> Output
    func set(_ newValue: Output, oldValue: @autoclosure () -> Input, transaction: Transaction) throws -> Input
}

extension Binding {
    @inlinable
    public func projecting<Transform: BindingTransform>(
        _ transform: Transform
    ) -> Binding<Transform.Output> where Transform.Input == Value {
        Binding<Transform.Output> {
            transform.get(wrappedValue)
        } set: { newValue, transaction in
            do {
                wrappedValue = try transform.set(newValue, oldValue: wrappedValue, transaction: transaction)
            } catch {
                os_log(.error, log: .default, "Projection %{public}@ failed with error: %{public}@", String(describing: Self.self), error.localizedDescription)
            }
        }
    }
}