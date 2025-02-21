//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

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
