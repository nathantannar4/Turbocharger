//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct SafeAreaInsetsObserver: VersionedViewModifier {
    @Binding var safeAreaInsets: EdgeInsets?

    public init(safeAreaInsets: Binding<EdgeInsets?>) {
        self._safeAreaInsets = safeAreaInsets
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func v4Body(content: Content) -> some View {
        content
            .onGeometryChange(for: EdgeInsets.self) { proxy in
                proxy.safeAreaInsets
            } action: { newValue in
                safeAreaInsets = newValue
            }
    }

    public func v1Body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppearAndChange(of: proxy.safeAreaInsets) { safeAreaInsets = $0 }
                }
                .hidden()
            )
    }
}
