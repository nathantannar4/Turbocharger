//
// Copyright (c) Nathan Tannar
//

import SwiftUI

public protocol AlignmentKey: AlignmentID {
    static func reduce(value: inout CGFloat?, n: Int, nextValue: CGFloat)
}

private struct AbstractAlignmentKey: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat { 0 }
}

extension AlignmentKey {
    public static func reduce(value: inout CGFloat?, n: Int, nextValue: CGFloat) {
        AbstractAlignmentKey._combineExplicit(childValue: nextValue, n, into: &value)
    }

    public static func _combineExplicit(
        childValue: CGFloat,
        _ n: Int,
        into parentValue: inout CGFloat?
    ) {
        reduce(value: &parentValue, n: n, nextValue: childValue)
    }
}

extension View {
    @inlinable
    public func alignmentGuide(
        _ g: VerticalAlignment,
        value: VerticalAlignment
    ) -> some View {
        alignmentGuide(g) { $0[value] }
    }

    @inlinable
    public func alignmentGuide(
        _ g: HorizontalAlignment,
        value: HorizontalAlignment
    ) -> some View {
        alignmentGuide(g) { $0[value] }
    }
}
