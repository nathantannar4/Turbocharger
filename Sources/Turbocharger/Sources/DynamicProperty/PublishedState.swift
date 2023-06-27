//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Combine

/// A property wrapper that can read and write a value but does
/// not invalidate a view when changed.
///
/// > Tip: Use ``PublishedState`` to improve performance
/// when your view does not need to be invalidated for every change.
/// Instead, use ``View/onReceive`` with ``PublishedState/publisher``
///
@propertyWrapper
@frozen
public struct PublishedState<Value>: DynamicProperty {

    public typealias Publisher = Published<Value>.Publisher

    @usableFromInline
    final class Storage: ObservableObject {
        @Published var value: Value

        @usableFromInline
        init(value: Value) {
            self.value = value
        }
    }

    @usableFromInline
    var storage: State<Storage>

    @inlinable
    public init(wrappedValue: Value) {
        storage = State<Storage>(wrappedValue: Storage(value: wrappedValue))
    }

    public var wrappedValue: Value {
        get { storage.wrappedValue.value }
        nonmutating set { storage.wrappedValue.value = newValue }
    }

    public var projectedValue: Binding<Value> {
        storage.projectedValue.value
    }

    public var publisher: Publisher {
        storage.wrappedValue.$value
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public static var _propertyBehaviors: UInt32 {
        State<Storage>._propertyBehaviors
    }
}
