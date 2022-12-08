//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// An `AlignmentID` that is resolved from multiple values
///
/// > Tip: Use ``VariadicAlignmentID`` to create alignments
/// similar to `.firstTextBaseline`
public protocol VariadicAlignmentID: AlignmentID {
    static func reduce(value: inout CGFloat?, n: Int, nextValue: CGFloat)
}

private struct DefaultAlignmentID: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat { 0 }
}

extension VariadicAlignmentID {
    public static func reduce(value: inout CGFloat?, n: Int, nextValue: CGFloat) {
        DefaultAlignmentID._combineExplicit(childValue: nextValue, n, into: &value)
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

    /// A modifier that transforms a vertical alignment to another
    @inlinable
    public func alignmentGuide(
        _ g: VerticalAlignment,
        value: VerticalAlignment
    ) -> some View {
        alignmentGuide(g) { $0[value] }
    }

    /// A modifier that transforms a horizontal alignment to another
    @inlinable
    public func alignmentGuide(
        _ g: HorizontalAlignment,
        value: HorizontalAlignment
    ) -> some View {
        alignmentGuide(g) { $0[value] }
    }
}

// MARK: - Previews

struct SecondTextBaseline: VariadicAlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context[.firstTextBaseline]
    }

    static func reduce(value: inout CGFloat?, n: Int, nextValue: CGFloat) {
        if n == 1 {
            value = nextValue
        }
    }
}

extension VerticalAlignment {
    static let secondTextBaseline = VerticalAlignment(SecondTextBaseline.self)
}

struct VariadicAlignmentID_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 48) {
            HStack(alignment: .firstTextBaseline) {
                Text("Label")

                VStack(alignment: .trailing) {
                    Text("One")
                    Text("Two")
                    Text("Three")
                }
                .font(.title)
            }

            HStack(alignment: .secondTextBaseline) {
                Text("Label")

                VStack(alignment: .trailing) {
                    Group {
                        Text("One")
                        Text("Two")
                        Text("Three")
                    }
                    .alignmentGuide(.secondTextBaseline) { d in
                        d[VerticalAlignment.firstTextBaseline]
                    }
                }
                .font(.title)
            }
        }
    }
}
