//
// Copyright (c) Nathan Tannar
//

import SwiftUI

/// A custom parameter attribute that constructs a `[Text]` from closures.
public typealias TextBuilder = ArrayBuilder<Text>

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
        Preview()
    }

    struct Preview: View {
        @State var flag = false

        var body: some View {
            VStack {
                Toggle(isOn: $flag) { Text("Flag") }

                Text(separator: " ") {
                    if flag {
                        Text("~")
                    }

                    Text("Hello")
                        .font(.headline)
                        .foregroundColor(.red)

                    Text("World")
                        .fontWeight(.light)

                    if flag {
                        Text("!")
                    } else {
                        Text(".")
                    }
                }
            }
        }
    }
}
