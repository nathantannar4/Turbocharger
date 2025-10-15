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
        @ViewBuilder success : (Success) -> SuccessContent,
        @ViewBuilder failure: (Failure) -> FailureContent
    ) {
        switch value {
        case .success(let value):
            self.content = .init(success(value))
        case .failure(let error):
            self.content = .init(failure(error))
        }
    }

    @inlinable
    public init<Success, Failure: Error>(
        _ value: Result<Success, Failure>?,
        @ViewBuilder success : (Success) -> SuccessContent,
        @ViewBuilder failure: (Failure?) -> FailureContent
    ) {
        switch value {
        case .some(let value):
            switch value {
            case .success(let value):
                self.content = .init(success(value))
            case .failure(let error):
                self.content = .init(failure(error))
            }
        case .none:
            self.content = .init(failure(nil))
        }
    }

    @inlinable
    public init<Success, Failure: Error>(
        _ value: Binding<Result<Success, Failure>>,
        @ViewBuilder success: (Binding<Success>) -> SuccessContent,
        @ViewBuilder failure: (Binding<Failure>) -> FailureContent
    ) {
        switch value.wrappedValue {
        case .success:
            let unwrapped = Binding(value[keyPath: \.success])!
            self.content = .init(success(unwrapped))
        case .failure:
            let unwrapped = Binding(value[keyPath: \.failure])!
            self.content = .init(failure(unwrapped))
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
        @ViewBuilder success: (Success) -> SuccessContent
    ) {
        self.init(value, success: success, failure: { _ in EmptyView() })
    }

    @inlinable
    public init<Success, Failure: Error>(
        _ value: Result<Success, Failure>?,
        @ViewBuilder success : (Success) -> SuccessContent
    ) {
        self.init(value, success: success, failure: { _ in EmptyView() })
    }

    @inlinable
    public init<Success, Failure: Error>(
        _ value: Binding<Result<Success, Failure>>,
        @ViewBuilder success: (Binding<Success>) -> SuccessContent
    ) {
        self.init(value, success: success, failure: { _ in EmptyView() })
    }
}

extension Result {

    @usableFromInline
    var success: Success? {
        get { try? get() }
        set {
            if let newValue {
                self = .success(newValue)
            }
        }
    }

    @usableFromInline
    var failure: Failure? {
        get {
            do {
                _ = try get()
                return nil
            } catch {
                return error
            }
        }
        set {
            if let newValue {
                self = .failure(newValue)
            }
        }
    }
}

// MARK: - Previews

struct ResultAdapter_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var value: Result<Int, Error> = .success(1)

        var body: some View {
            VStack {
                ResultAdapter($value) { value in
                    VStack {
                        Text(value.wrappedValue.description)

                        Button {
                            value.wrappedValue += 1
                        } label: {
                            Text("Increment")
                        }
                    }
                } failure: { _ in
                    Text("Error")
                }
            }
        }
    }
}
