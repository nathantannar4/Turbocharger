//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ProposedSizeObserver: VersionedViewModifier {
    @Binding var size: ProposedSize

    public init(size: Binding<ProposedSize>) {
        self._size = size
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func v4Body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newValue in
                size = ProposedSize(size: newValue)
            }
            .onDisappear { size = .unspecified }
    }

    public func v1Body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .hidden()
                        .onAppearAndChange(of: proxy.size) { size = ProposedSize(size: $0) }
                        .onDisappear { size = .unspecified }
                }
            )
    }
}
