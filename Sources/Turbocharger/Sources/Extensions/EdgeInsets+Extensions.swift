//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension EdgeInsets {
    public static let zero = EdgeInsets()

    public static func horizontal(_ inset: CGFloat) -> EdgeInsets {
        EdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
    }

    public static func vertical(_ inset: CGFloat) -> EdgeInsets {
        EdgeInsets(top: inset, leading: 0, bottom: inset, trailing: 0)
    }
}

#if os(macOS)
extension NSEdgeInsets {
    public init(
        edgeInsets: EdgeInsets,
        layoutDirection: LayoutDirection
    ) {
        self.init(
            top: edgeInsets.top,
            left: layoutDirection == .leftToRight ? edgeInsets.leading : edgeInsets.trailing,
            bottom: edgeInsets.bottom,
            right: layoutDirection == .leftToRight ? edgeInsets.trailing : edgeInsets.leading
        )
    }
}
#else
extension UIEdgeInsets {
    public init(
        edgeInsets: EdgeInsets,
        layoutDirection: LayoutDirection
    ) {
        self.init(
            top: edgeInsets.top,
            left: layoutDirection == .leftToRight ? edgeInsets.leading : edgeInsets.trailing,
            bottom: edgeInsets.bottom,
            right: layoutDirection == .leftToRight ? edgeInsets.trailing : edgeInsets.leading
        )
    }
}
#endif
