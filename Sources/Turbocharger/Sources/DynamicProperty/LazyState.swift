//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A property wrapper that defers initialization similar to `StateObject`
@propertyWrapper
@frozen
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@MainActor @preconcurrency
public struct LazyState<Value>: DynamicProperty {

    @usableFromInline
    class Storage: ObservableObject {
        var value: Value

        @usableFromInline
        init(value: @autoclosure @escaping () -> Value) {
            self.value = value()
        }
    }
    @usableFromInline
    var storage: StateObject<Storage>

    @inlinable
    public init(wrappedValue thunk: @autoclosure @escaping () -> Value) {
        self.storage = StateObject(wrappedValue: Storage(value: thunk()))
    }

    public var wrappedValue: Value {
        get { storage.wrappedValue.value }
        set { storage.wrappedValue.value = newValue }
    }

    @MainActor @preconcurrency
    public var projectedValue: Binding<Value> {
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

// MARK: - Previews

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
struct LazyState_Previews: PreviewProvider {

    static var previews: some View {
        ConditionalView {
            ContentView()
        }
    }

    struct ConditionalView<Content: View>: View {
        var content: Content
        @State var isHidden = true

        init(
            @ViewBuilder content: () -> Content
        ) {
            self.content = content()
        }

        var body: some View {
            VStack {
                Button {
                    isHidden.toggle()
                } label: {
                    Text("Toggle")
                }

                if !isHidden {
                    content
                }
            }
        }
    }

    struct ContentView: View {
        @Observable
        class ViewModel {
            var observableValue = 0
            @ObservationIgnored var nonObservableValue = 0
            init() {
                print("init ViewModel")
            }
        }
        @LazyState var viewModel = ViewModel()

        var body: some View {
            VStack {
                Button {
                    viewModel.observableValue += 1
                } label: {
                    Text(viewModel.observableValue, format: .number)
                }

                Button {
                    viewModel.nonObservableValue += 1
                } label: {
                    Text(viewModel.nonObservableValue, format: .number)
                }
            }
        }
    }
}
