//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Sequence where Element == CGRect {
    var union: CGRect {
        reduce(.null, { $0.union($1) })
    }
}
