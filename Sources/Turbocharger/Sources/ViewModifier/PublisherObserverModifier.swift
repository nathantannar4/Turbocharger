//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Combine

extension View {

    public func onReceive<T: Publisher>(
        _ publisher: T,
        update value: Binding<T.Output>
    ) -> some View where T.Failure == Never {
        modifier(PublisherObserverModifier(publisher: publisher, value: value))
    }
}

@frozen
public struct PublisherObserverModifier<T: Publisher>: ViewModifier where T.Failure == Never {

    public var publisher: T
    public var value: Binding<T.Output>

    public init(publisher: T, value: Binding<T.Output>) {
        self.publisher = publisher
        self.value = value
    }

    public func body(content: Content) -> some View {
        content
            .onReceive(publisher) { newValue in
                value.wrappedValue = newValue
            }
    }
}
