//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// The style for ``LabeledView``
@available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
@available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
@available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
@available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
@available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
public protocol LabeledViewStyle: ViewStyle where Configuration == LabeledViewStyleConfiguration {
}

/// The configuration parameters for ``LabeledView``
@available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
@available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
@available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
@available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
@available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
@frozen
public struct LabeledViewStyleConfiguration {
    /// A type-erased label of a ``LabeledView``
    public struct Label: ViewAlias { }
    public var label: Label { .init() }

    /// A type-erased content of a ``LabeledView``
    public struct Content: ViewAlias { }
    public var content: Content { .init() }
}

/// A backwards compatible port of `LabeledContent`
@available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
@available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
@available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
@available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
@available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
public struct LabeledView<Label: View, Content: View>: View {
    var label: Label
    var content: Content

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.content = content()
    }

    public var body: some View {
        LabeledViewBody(
            configuration: .init()
        )
        .viewAlias(LabeledViewStyleConfiguration.Label.self) { label }
        .viewAlias(LabeledViewStyleConfiguration.Content.self) { content }
    }
}

extension LabeledView where
    Label == LabeledViewStyleConfiguration.Label,
    Content == LabeledViewStyleConfiguration.Content
{
    public init(_ configuration: LabeledViewStyleConfiguration) {
        self.label = configuration.label
        self.content = configuration.content
    }
}

private struct LabeledViewBody: ViewStyledView {
    var configuration: LabeledViewStyleConfiguration

    static var defaultStyle: DefaultLabeledViewStyle { .automatic }
}

extension View {
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Please use the built in LabeledContentStyle with LabeledContent")
    public func labeledViewStyle<Style: LabeledViewStyle>(_ style: Style) -> some View {
        styledViewStyle(LabeledViewBody.self, style: style)
    }
}

extension LabeledViewStyle where Self == DefaultLabeledViewStyle {
    public static var automatic: DefaultLabeledViewStyle { DefaultLabeledViewStyle() }
}

public struct DefaultLabeledViewStyle: LabeledViewStyle {

    @Environment(\.labelsHidden) var labelsHidden

    public init() { }

    public func makeBody(configuration: LabeledViewStyleConfiguration) -> some View {
        HStack(alignment: .label) {
            if !labelsHidden {
                configuration.label
            }

            configuration.content
                .frame(
                    maxWidth: labelsHidden ? nil : .infinity,
                    alignment: .trailing
                )
        }
    }
}

// MARK: - Previews

struct CustomLabeledViewStyle: LabeledViewStyle {
    func makeBody(configuration: LabeledViewStyleConfiguration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
            configuration.content
        }
    }
}

struct RedLabeledViewStyle: LabeledViewStyle {
    func makeBody(configuration: LabeledViewStyleConfiguration) -> some View {
        LabeledView {
            configuration.content
        } label: {
            configuration.label
                .background(Color.red)
        }
    }
}

struct LabeledViewStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LabeledView {
                Text("Content")
            } label: {
                Text("Label")
            }

            LabeledView {
                Text("Content")
            } label: {
                Text("Label")
            }
            .labelsHidden()

            LabeledView {
                Text("Content")
                    .font(.largeTitle)
            } label: {
                Text("Label")
            }

            LabeledView {
                VStack(alignment: .leading, spacing: 1) {
                    Color.red.frame(height: 30)

                    Color.red.frame(height: 30)
                }
                .alignmentGuide(.label, value: .center)
            } label: {
                Text("Label")
            }

            LabeledView {
                Text("Content")
            } label: {
                Text("Label")
            }
            .labeledViewStyle(CustomLabeledViewStyle())

            LabeledView {
                Text("Content")
            } label: {
                Text("Label")
            }
            .labeledViewStyle(RedLabeledViewStyle())

            LabeledView {
                Text("Content")
            } label: {
                Text("Label")
            }
            .labeledViewStyle(CustomLabeledViewStyle())
            .labeledViewStyle(RedLabeledViewStyle())

            LabeledView {
                Text("Content")
            } label: {
                Text("Label")
            }
            .labeledViewStyle(RedLabeledViewStyle())
            .labeledViewStyle(CustomLabeledViewStyle())
        }
    }
}
