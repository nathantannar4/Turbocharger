//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension AnyTransition {

    /// Returns a transition that blurs the view.
    public static let blur = AnyTransition.modifier(
        active: BlurModifier(radius: 5),
        identity: BlurModifier(radius: 0)
    )

    /// Returns a transition that blurs the view.
    public static func blur(radius: CGFloat, opaque: Bool = false) -> AnyTransition {
        .modifier(
            active: BlurModifier(radius: radius, opaque: opaque),
            identity: BlurModifier(radius: 0, opaque: opaque)
        )
    }
}

/// A modifier that blurs the content
@frozen
public struct BlurModifier: ViewModifier {

    public var radius: CGFloat
    public var opaque: Bool

    public init(radius: CGFloat, opaque: Bool = false) {
        self.radius = radius
        self.opaque = opaque
    }

    public func body(content: Content) -> some View {
        content
            .blur(radius: radius, opaque: opaque)
    }
}

// MARK: - Previews

struct BlurModifier_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var isHidden = false

        var body: some View {
            VStack {
                Button("Toggle") {
                    withAnimation(.linear(duration: 1)) {
                        isHidden.toggle()
                    }
                }

                HStack(spacing: 24) {
                    if !isHidden {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 50, height: 50)
                    }

                    if !isHidden {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 50, height: 50)
                            .transition(.blur.combined(with: .opacity))
                    }

                    if !isHidden {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 50, height: 50)
                            .transition(.blur)
                    }

                    if !isHidden {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 50, height: 50)
                            .transition(.blur(radius: 20))
                    }

                    if !isHidden {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 50, height: 50)
                            .transition(.blur(radius: 100))
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
}
