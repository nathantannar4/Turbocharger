//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension VerticalAlignment {
    private struct LabelAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.firstTextBaseline]
        }
    }

    public static let label = VerticalAlignment(LabelAlignment.self)
}

// MARK: - Previews

struct LabelAlignment_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack(alignment: .label) {
                Text("Label")

                VStack(alignment: .trailing) {
                    Text("One")
                    Text("Two")
                        .alignmentGuide(.label, value: .firstTextBaseline)
                    Text("Three")
                }
                .font(.title)
            }
        }
    }
}
