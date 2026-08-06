//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

extension Transaction {

    public func animation(_ animation: Animation?) -> Transaction {
        var copy = self
        copy.animation = animation
        return copy
    }

    public func disablesAnimations(_ disablesAnimations: Bool) -> Transaction {
        var copy = self
        copy.disablesAnimations = disablesAnimations
        return copy
    }
}

#if !os(watchOS)

@inline(__always)
public func withAnimation<Result>(
    _ animation: Animation = .default,
    _ body: () throws -> Result,
    completion: @escaping () -> Void
) rethrows -> Result {
    try withTransaction(Transaction(animation: animation), body, completion: completion)
}

@inline(__always)
public func withTransaction<Result>(
    _ transaction: Transaction,
    _ body: () throws -> Result,
    completion: @escaping () -> Void
) rethrows -> Result {
    defer { withCATransaction(completion) }
    return try withTransaction(transaction, body)
}

#endif
