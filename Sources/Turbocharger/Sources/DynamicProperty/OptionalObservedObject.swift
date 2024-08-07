//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Combine

/// A property wrapper that subscribes to an optional observable
/// object and invalidates a view whenever the observable object changes.
@propertyWrapper
@frozen
@MainActor @preconcurrency
public struct OptionalObservedObject<ObjectType: ObservableObject>: DynamicProperty {

    @usableFromInline
    @MainActor @preconcurrency
    class Storage: ObservableObject {
        weak var value: ObjectType? {
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
    @MainActor @preconcurrency
    public init(wrappedValue: ObjectType?) {
        storage = ObservedObject<Storage>(wrappedValue: Storage(value: wrappedValue))
    }

    @MainActor @preconcurrency
    public var wrappedValue: ObjectType? {
        get { storage.wrappedValue.value }
        nonmutating set { storage.wrappedValue.value = newValue }
    }

    @MainActor @preconcurrency
    public var projectedValue: Binding<ObjectType?> {
        storage.projectedValue.value
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public nonisolated static var _propertyBehaviors: UInt32 {
        #if swift(>=5.9)
        MainActor.assumeIsolated {
            StateObject<Storage>._propertyBehaviors
        }
        #else
        StateObject<Storage>._propertyBehaviors
        #endif
    }
}
