//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@frozen
public struct FontPointSizeHeightModifier: EnvironmentalModifier {

    @inlinable
    public init() { }

    public nonisolated func resolve(in environment: EnvironmentValues) -> some ViewModifier {
        let font = environment.font ?? .body
        #if os(iOS) || os(visionOS) || os(tvOS) || os(watchOS)
        let pointSize = font.toUIFont(in: environment)?.pointSize
        #else
        let pointSize = font.toNSFont(in: environment)?.pointSize
        #endif
        return Modifier(pointSize: pointSize)
    }

    private struct Modifier: ViewModifier {
        var pointSize: CGFloat?

        public func body(content: Content) -> some View {
            content
                .frame(height: pointSize)
        }
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
            }
            .font(isLarge ? .title : .subheadline)
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
