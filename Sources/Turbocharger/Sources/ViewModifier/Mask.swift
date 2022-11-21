//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension View {
    @inlinable
    public func invertedMask<Mask: View>(
        alignment: Alignment = .center,
        @ViewBuilder mask: () -> Mask
    ) -> some View {
        self.mask(
            Rectangle()
                .ignoresSafeArea()
                .overlay(
                    mask()
                        .blendMode(.destinationOut),
                    alignment: alignment
                )
        )
    }
}
