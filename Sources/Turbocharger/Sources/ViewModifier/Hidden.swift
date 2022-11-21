//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct HiddenModifier: ViewModifier {
    public var isHidden: Bool

    @inlinable
    public init(isHidden: Bool) {
        self.isHidden = isHidden
    }

    public func body(content: Content) -> some View {
        if isHidden {
            content.hidden()
        } else {
            content
        }
    }
}

extension View {
    @inlinable
    public func hidden(_ isHidden: Bool) -> some View {
        modifier(HiddenModifier(isHidden: isHidden))
    }
}
