//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A custom parameter attribute that constructs an array from closures.
@frozen
@resultBuilder
public struct ArrayBuilder<Element> {

    @inlinable
    public static func buildBlock() -> [Optional<Element>] {
        []
    }

    @inlinable
    public static func buildPartialBlock(
        first: [Optional<Element>]
    ) -> [Optional<Element>] {
        first
    }

    @inlinable
    public static func buildPartialBlock(
        accumulated: [Optional<Element>],
        next: [Optional<Element>]
    ) -> [Optional<Element>] {
        accumulated + next
    }

    @inlinable
    public static func buildExpression(
        _ expression: Element
    ) -> [Optional<Element>] {
        [expression]
    }

    @inlinable
    public static func buildEither(
        first component: [Optional<Element>]
    ) -> [Optional<Element>] {
        component
    }

    @inlinable
    public static func buildEither(
        second component: [Optional<Element>]
    ) -> [Optional<Element>] {
        component
    }

    @inlinable
    public static func buildOptional(
        _ component: [Optional<Element>]?
    ) -> [Optional<Element>] {
        component ?? []
    }

    @inlinable
    public static func buildLimitedAvailability(
        _ component: [Optional<Element>]
    ) -> [Optional<Element>] {
        component
    }

    @inlinable
    public static func buildArray(
        _ components: [Optional<Element>]
    ) -> [Optional<Element>] {
        components
    }

    @inlinable
    public static func buildBlock(
        _ components: [Optional<Element>]...
    ) -> [Optional<Element>] {
        components.flatMap { $0 }
    }

    public static func buildFinalResult(
        _ component: [Optional<Element>]
    ) -> [Element] {
        component.compactMap { $0 }
    }
}
