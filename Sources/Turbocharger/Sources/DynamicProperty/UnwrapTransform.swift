//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Binding {

    /// Unwraps a `Binding` with an optional wrapped value to an optional `Binding`
    @inlinable
    public func unwrap<Wrapped>() -> Binding<Wrapped>? where Optional<Wrapped> == Value {
        guard let value = self.wrappedValue else { return nil }
        return Binding<Wrapped>(
            get: { return value },
            set: { value, transaction in
                self.transaction(transaction).wrappedValue = value
            }
        )
    }
}
