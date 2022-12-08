//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Combine

/// A property wrapper that instantiates an optional observable object
/// and invalidates a view whenever the observable object changes.
@propertyWrapper
@frozen
public struct OptionalStateObject<ObjectType: ObservableObject>: DynamicProperty {

    @usableFromInline
    class Storage: ObservableObject {
        var value: ObjectType? {
            didSet {
                if oldValue !== value {
                    value.map { bind(to: $0) }
                    objectWillChange.send()
                }
            }
        }

        var cancellable: AnyCancellable?

        @usableFromInline
        init(value: ObjectType?) {
            self.value = value
            value.map { bind(to: $0) }
        }

        func bind(to object: ObjectType) {
            cancellable = object.objectWillChange
                .sink { [unowned self] _ in
                    self.objectWillChange.send()
                }
        }
    }

    @usableFromInline
    var storage: ObservedObject<Storage>

    @inlinable
    public init(wrappedValue: ObjectType?) {
        storage = ObservedObject<Storage>(wrappedValue: Storage(value: wrappedValue))
    }

    public var wrappedValue: ObjectType? {
        get { storage.wrappedValue.value }
        nonmutating set { storage.wrappedValue.value = newValue }
    }

    public var projectedValue: Binding<ObjectType?> {
        storage.projectedValue.value
    }
}
