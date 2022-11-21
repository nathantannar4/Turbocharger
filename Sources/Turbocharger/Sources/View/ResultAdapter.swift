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
    init(content: ConditionalContent<SuccessContent, FailureContent>) {
        self.content = content
    }

    @inlinable
    public init<Success, Failure: Error>(
        _ value: Result<Success, Failure>,
        @ViewBuilder content: (Success) -> SuccessContent,
        @ViewBuilder placeholder: (Failure) -> FailureContent
    ) {
        switch value {
        case .success(let success):
            self.init(content: .init(content(success)))
        case .failure(let error):
            self.init(content: .init(placeholder(error)))
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
}
