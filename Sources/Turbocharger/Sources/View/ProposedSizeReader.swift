//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ProposedSizeReader<Content: View>: View {
    let content: (ProposedSize) -> Content

    @State var size: ProposedSize = .unspecified

    public init(@ViewBuilder content: @escaping (ProposedSize) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(size)
            .modifier(ProposedSizeObserver(size: $size))
    }
}
