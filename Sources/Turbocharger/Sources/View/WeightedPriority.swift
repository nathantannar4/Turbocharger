//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

/// A view trait that defines the relative weight priority of a subview
/// when within a ``WeightedVStack`` or a ``WeightedHStack``.
public struct LayoutWeightPriority: TraitValueKey {
    public static let defaultValue: Double = 1
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension LayoutSubviews.Element {
    var layoutWeightPriority: Double {
        self[LayoutWeightPriority.self]
    }
}

extension VariadicView.Subview {
    var layoutWeightPriority: Double {
        self[LayoutWeightPriority.self]
    }
}

extension View {
    @ViewBuilder
    public func layoutWeight(_ value: Double) -> some View {
        trait(LayoutWeightPriority.self, value)
    }
}
