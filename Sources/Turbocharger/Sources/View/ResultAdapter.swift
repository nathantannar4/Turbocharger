//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A view maps a `Result` value to it's `SuccessContent` or `FailureContent`.
@frozen
public struct ResultAdapter<
    SuccessContent: View,
    FailureContent: View
>: View {

    @usableFromInline
    var content: ConditionalContent<SuccessContent, FailureContent>

    @inlinable
    public init<Success, Failure: Error>(
        _ value: Result<Success, Failure>,
        @ViewBuilder content: (Success) -> SuccessContent,
        @ViewBuilder placeholder: (Failure) -> FailureContent
    ) {
        switch value {
        case .success(let success):
            self.content = .init(content(success))
        case .failure(let error):
            self.content = .init(placeholder(error))
        }
    }

    @inlinable
    public init<Success, Failure: Error>(
        _ value: Binding<Result<Success, Failure>>,
        @ViewBuilder content: (Binding<Success>) -> SuccessContent,
        @ViewBuilder placeholder: (Binding<Failure>) -> FailureContent
    ) {
        switch value.wrappedValue {
        case .success(let success):
            let unwrapped = Binding(
                get: { success },
                set: { newValue in
                    value.wrappedValue = .success(newValue)
                })
            self.content = .init(content(unwrapped))
        case .failure(let error):
            let unwrapped = Binding(
                get: { error },
                set: { newValue in
                    value.wrappedValue = .failure(newValue)
                })
            self.content = .init(placeholder(unwrapped))
        }
    }

    public var body: some View {
        content
    }
}

extension ResultAdapter where FailureContent == EmptyView {
    @inlinable
    public init<Success, Failure: Error>(
        _ value: Result<Success, Failure>,
        @ViewBuilder content: (Success) -> SuccessContent
    ) {
        self.init(value, content: content, placeholder: { _ in EmptyView() })
    }

    @inlinable
    public init<Success, Failure: Error>(
        _ value: Binding<Result<Success, Failure>>,
        @ViewBuilder content: (Binding<Success>) -> SuccessContent
    ) {
        self.init(value, content: content, placeholder: { _ in EmptyView() })
    }
}
