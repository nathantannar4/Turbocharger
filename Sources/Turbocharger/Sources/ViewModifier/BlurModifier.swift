//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@MainActor
@available(iOS, deprecated: 17.0, message: "Use BlurTransition")
@available(macOS, deprecated: 14.0, message: "Use BlurTransition")
@available(tvOS, deprecated: 17.0, message: "Use BlurTransition")
@available(watchOS, deprecated: 10.0, message: "Use BlurTransition")
@available(visionOS, deprecated: 1.0, message: "Use BlurTransition")
extension AnyTransition {

    /// A transition that blurs the view.
    public static let blur = AnyTransition.modifier(
        active: BlurModifier(radius: 6),
        identity: BlurModifier(radius: 0)
    )

    /// A transition that blurs the view.
    public static func blur(radius: CGFloat, opaque: Bool = false) -> AnyTransition {
        .modifier(
            active: BlurModifier(radius: radius, opaque: opaque),
            identity: BlurModifier(radius: 0, opaque: opaque)
        )
    }
}

/// A transition that blurs the view
@frozen
@MainActor @preconcurrency
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public struct BlurTransition: Transition {

    public struct Configuration: Equatable, Sendable {
        public var radius: CGFloat
        public var opaque: Bool

        public init(radius: CGFloat = 6, opaque: Bool = false) {
            self.radius = radius
            self.opaque = opaque
        }
    }

    public var configuration: Configuration

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .modifier(
                BlurModifier(
                    radius: phase.isIdentity ? 0 : configuration.radius,
                    opaque: configuration.opaque
                )
            )
    }

    public static var properties: TransitionProperties {
        TransitionProperties(hasMotion: false)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension Transition where Self == BlurTransition {

    /// A transition that blurs the view.
    public static var blur: BlurTransition {
        BlurTransition(configuration: .init())
    }

    /// A transition that blurs the view.
    public static func blur(
        radius: CGFloat,
        opaque: Bool = false
    ) -> BlurTransition {
        BlurTransition(
            configuration: BlurTransition.Configuration(
                radius: radius,
                opaque: opaque
            )
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
        ZStack {
            Preview()
        }
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

                VStack {
                    HStack(spacing: 24) {
                        if !isHidden {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                                .transition(.identity)
                        }

                        if !isHidden {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                                .transition(.opacity)
                        }
                    }
                    .frame(height: 50)

                    HStack(spacing: 24) {
                        if !isHidden {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                                .transition(.blur.combined(with: .opacity))
                        }

                        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *), !isHidden {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                                .transition(.blurReplace)
                        }
                    }
                    .frame(height: 50)

                    HStack(spacing: 24) {
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
                    .frame(height: 50)

                    if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                        HStack(spacing: 24) {
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
                        .frame(height: 50)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
}
