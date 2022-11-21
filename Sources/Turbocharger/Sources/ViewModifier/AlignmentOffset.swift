//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension View {
    public func alignmentGuideAdjustment(anchor: UnitPoint) -> some View {
        modifier(AlignmentGuideAdjustmentModifier(anchor: anchor, offset: .zero))
    }

    public func alignmentGuideAdjustment(x: CGFloat, y: CGFloat) -> some View {
        modifier(AlignmentGuideAdjustmentModifier(anchor: .zero, offset: CGPoint(x: x, y: y)))
    }

    public func alignmentGuideAdjustment(anchor: UnitPoint, x: CGFloat, y: CGFloat) -> some View {
        modifier(AlignmentGuideAdjustmentModifier(anchor: anchor, offset: CGPoint(x: x, y: y)))
    }
}

struct AlignmentGuideAdjustmentModifier: ViewModifier {
    var anchor: UnitPoint
    var offset: CGPoint

    func body(content: Content) -> some View {
        content
            .alignmentGuide(.top) { $0[.top] + ($0.height * anchor.y) + offset.y }
            .alignmentGuide(.bottom) { $0[.bottom] - ($0.height * anchor.y) - offset.y }
            .alignmentGuide(.trailing) { $0[.trailing] - ($0.width * anchor.x) - offset.x }
            .alignmentGuide(.leading) { $0[.leading] + ($0.width * anchor.x) + offset.x }
    }
}
