//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct IsNotNilTransform<Input>: BindingTransform {

    @inlinable
    public init() { }

    public func get(_ value: Input?) -> Bool {
        value != nil
    }

    public func set(_ newValue: Output, oldValue: @autoclosure () -> Input?, transaction: Transaction) throws -> Input? {
        if !newValue {
            return nil
        }
        return oldValue()
    }
}

extension Binding {
    @inlinable
    public func isNotNil<Wrapped>() -> Binding<Bool> where Optional<Wrapped> == Value {
        projecting(IsNotNilTransform())
    }
}

// MARK: - Previews

struct IsNotNilTransform_Previews: PreviewProvider {
    struct Preview: View {
        @State var value: String?

        var body: some View {
            VStack {
                Toggle(isOn: $value.isNotNil()) {
                    if let value = value {
                        Text(value)
                    }
                }

                Button {
                    value = "Hello, World"
                } label: {
                    Text("Add Text")
                }
            }
        }
    }
    static var previews: some View {
        Preview()
    }
}
