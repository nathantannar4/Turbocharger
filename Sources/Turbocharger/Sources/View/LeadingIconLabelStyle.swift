//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@frozen
public struct LeadingIconLabelStyle: LabelStyle {

    public var spacing: CGFloat?

    @inlinable
    public init(spacing: CGFloat? = nil) {
        self.spacing = spacing
    }

    public func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextMidline, spacing: spacing) {
            configuration.icon
                .aspectRatio(nil, contentMode: .fit)
                .modifier(FontPointSizeHeightModifier())

            configuration.title
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension LabelStyle where Self == LeadingIconLabelStyle {

    public static var leadingIcon: LeadingIconLabelStyle { .init() }

    public static func leadingIcon(spacing: CGFloat?) -> LeadingIconLabelStyle { .init(spacing: spacing) }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct LeadingIconLabelStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Label {
                Text("Title")
            } icon: {
                Image(systemName: "apple.logo")
                    .resizable()
            }
            .labelStyle(.leadingIcon)

            Label {
                Text("Title")
            } icon: {
                Image(systemName: "apple.logo")
                    .resizable()
                    .padding(4)
            }
            .labelStyle(.leadingIcon)

            Label {
                Text("Title")
            } icon: {
                Image(systemName: "apple.logo")
                    .resizable()
                    .padding(-4)
            }
            .labelStyle(.leadingIcon)

            Label {
                Text("Title")
            } icon: {
                Image(systemName: "apple.logo")
                    .resizable()
            }
            .labelStyle(.leadingIcon)
            .font(.title)

            Label {
                Text("Title")
            } icon: {
                Image(systemName: "apple.logo")
                    .resizable()
            }
            .labelStyle(.leadingIcon)
            .font(.caption)

            Label {
                Text("Title")
            } icon: {
                Rectangle()
                    .frame(width: 100)
            }
            .labelStyle(.leadingIcon)
            .font(.headline)

            Label {
                Text("Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat.")
            } icon: {
                Image(systemName: "apple.logo")
                    .resizable()
            }
            .labelStyle(.leadingIcon)
            .font(.body)

            Label {
                Text("Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat.")
            } icon: {
                Image(systemName: "apple.logo")
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            .labelStyle(.leadingIcon)
            .font(.body)
        }
    }
}
