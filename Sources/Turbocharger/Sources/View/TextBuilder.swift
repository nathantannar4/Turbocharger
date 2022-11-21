//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A custom parameter attribute that constructs a `[Text]` from closures.
@resultBuilder
public struct TextBuilder {

    public static func buildBlock() -> [Text] {
        []
    }

    static func buildEither(first component: Text) -> [Text] {
        [component]
    }

    static func buildEither(second component: Text) -> [Text] {
        [component]
    }

    public static func buildOptional(_ component: Text?) -> [Text] {
        component.map { [$0] } ?? []
    }

    public static func buildLimitedAvailability(_ component: Text) -> [Text] {
        [component]
    }

    public static func buildArray(_ components: [Text]) -> [Text] {
        components
    }

    public static func buildBlock(_ components: Text...) -> [Text] {
        components
    }

}

extension Text {

    @_disfavoredOverload
    @inlinable
    public init<S: StringProtocol>(
        separator: S,
        @TextBuilder blocks: () -> [Text]
    ) {
        self.init(separator: Text(separator), blocks: blocks)
    }

    @inlinable
    public init(
        separator: LocalizedStringKey,
        @TextBuilder blocks: () -> [Text]
    ) {
        self.init(separator: Text(separator), blocks: blocks)
    }

    @inlinable
    public init(
        separator: Text,
        @TextBuilder blocks: () -> [Text]
    ) {
        let blocks = blocks()
        switch blocks.count {
        case 0:
            self = Text(verbatim: "")

        case 1:
            self = blocks[0]

        default:
            self = blocks.dropFirst().reduce(into: blocks[0]) { result, text in
                result = result + separator + text
            }
        }
    }
}

// MARK: - Previews

struct TextBuilder_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text(separator: ", ") {
                Text("Hello")
                    .font(.headline)
                    .foregroundColor(.red)

                Text("World")
                    .fontWeight(.light)
            }
        }
    }
}
