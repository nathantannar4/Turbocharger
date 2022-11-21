//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct FormatTransform<F: ParseableFormatStyle>: BindingTransform where F.FormatInput: Equatable, F.FormatOutput == String {
    public typealias Input = F.FormatInput
    public typealias Output = F.FormatOutput

    @usableFromInline
    var format: F
    @usableFromInline
    var defaultValue: Input?

    @inlinable
    public init(format: F, defaultValue: Input? = nil) {
        self.format = format
        self.defaultValue = defaultValue
    }

    public func get(_ value: Input) -> Output {
        format.format(value)
    }

    public func set(_ newValue: Output, oldValue: @autoclosure () -> Input, transaction: Transaction) throws -> Input {
        do {
            return try format.parseStrategy.parse(newValue)
        } catch {
            if let defaultValue = defaultValue {
                return defaultValue
            }
            throw error
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Binding {
    @inlinable
    public func format<F: ParseableFormatStyle>(
        _ format: F,
        defaultValue: F.FormatInput? = nil
    ) -> Binding<F.FormatOutput> where F.FormatInput: Equatable, F.FormatOutput == String, Value == F.FormatInput {
        projecting(FormatTransform(format: format, defaultValue: defaultValue))
    }
}
