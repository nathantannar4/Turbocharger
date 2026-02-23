//
// Copyright (c) Nathan Tannar
//

import SwiftUI

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
extension EdgeInsets {

    public init(
        edgeInsets: UIEdgeInsets,
        layoutDirection: UITraitEnvironmentLayoutDirection
    ) {
        self.init(
            top: edgeInsets.top,
            leading: layoutDirection == .leftToRight ? edgeInsets.left : edgeInsets.right,
            bottom: edgeInsets.right,
            trailing: layoutDirection == .leftToRight ? edgeInsets.right : edgeInsets.left
        )
    }
}

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
