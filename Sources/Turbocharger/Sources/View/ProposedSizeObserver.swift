//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ProposedSizeObserver: ViewModifier {
    @Binding var size: ProposedSize

    public init(size: Binding<ProposedSize>) {
        self._size = size
    }

    public func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .hidden()
                        .onAppear { size = ProposedSize(size: proxy.size) }
                        .onDisappear { size = .unspecified }
                        .onChange(of: proxy.size) { size = ProposedSize(size: $0) }
                }
            )
    }
}
