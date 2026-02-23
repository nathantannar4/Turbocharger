//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@frozen
public struct FontPointSizeHeightModifier: ViewModifier {

    @Environment(\.font) var font

    @inlinable
    public init() { }

    public func body(content: Content) -> some View {
        let font = font ?? .body
        #if os(iOS) || os(tvOS) || os(watchOS)
        let fontSize = font.toUIFont()?.pointSize
        #else
        let fontSize = font.toNSFont()?.pointSize
        #endif
        content
            .frame(height: fontSize)
    }
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct FontPointSizeHeightModifier_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var isLarge = false

        var body: some View {
            Button {
                isLarge.toggle()
            } label: {
                ChildView()
                    .equatable()
                    .dynamicTypeSize(isLarge ? .xxxLarge : .large)
            }
        }

        struct ChildView: View, Equatable {
            var body: some View {
                HStack {
                    Circle()
                        .modifier(FontPointSizeHeightModifier())

                    Text("Hello, World")
                }
            }
        }
    }
}
