//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Transaction {
    public var isAnimated: Bool {
        let isAnimated = animation != nil
        return isAnimated
    }
}

extension Optional where Wrapped == Transaction {
    public var isAnimated: Bool {
        switch self {
        case .none:
            return false
        case .some(let transation):
            return transation.isAnimated
        }
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

@inline(__always)
public func withCATransaction(
    _ completion: @escaping () -> Void
) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    CATransaction.commit()
}

#endif
