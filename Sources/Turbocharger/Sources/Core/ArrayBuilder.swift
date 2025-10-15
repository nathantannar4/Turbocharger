//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A custom parameter attribute that constructs an array from closures.
@frozen
@resultBuilder
public struct ArrayBuilder<Element> {

    public static func buildBlock() -> [Element] { [] }

    public static func buildPartialBlock(
        first: Void
    ) -> [Element] { [] }

    public static func buildPartialBlock(
        first: Never
    ) -> [Element] {}

    public static func buildExpression(
        _ component: Element?
    ) -> [Element] {
        guard let component else { return []}
        return [component]
    }

    public static func buildExpression(
        _ components: [Element]
    ) -> [Element] {
        components
    }

    public static func buildIf(
        _ component: [Element]?
    ) -> [Element] {
        component ?? []
    }

    public static func buildEither(
        first: [Element]
    ) -> [Element] { first }

    public static func buildEither(
        second: [Element]
    ) -> [Element] {
        second
    }

    public static func buildArray(
        _ components: [[Element]]
    ) -> [Element] {
        components.flatMap { $0 }
    }

    public static func buildPartialBlock(
        first: Element
    ) -> [Element] {
        [first]
    }

    public static func buildPartialBlock(
        first: [Element]
    ) -> [Element] {
        first
    }

    public static func buildPartialBlock(
        accumulated: [Element],
        next: Element
    ) -> [Element] {
        accumulated + [next]
    }

    public static func buildPartialBlock(
        accumulated: [Element],
        next: [Element]
    ) -> [Element] {
        accumulated + next
    }
}
