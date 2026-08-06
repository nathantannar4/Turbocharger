//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)

import SwiftUI
import Engine

/// Ignores the `UIHostingConfiguration` constraints, such as disabling
/// `UIViewControllerRepresentable`'s from being used.
@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct IgnoreHostingConfigurationConstraintsModifier: VersionedViewModifier {

    @inlinable
    public init() { }

    public func v4Body(content: Content) -> some View {
        content
            .modifier(Modifier())
    }

    private struct Modifier: ViewInputsModifier {
        nonisolated static func makeInputs(inputs: inout ViewInputs) {
            inputs["IsInHostingConfiguration"] = false
        }
    }
}

@available(iOS 14.0, tvOS 14.0, *)
extension View {

    /// Ignores the `UIHostingConfiguration` constraints, such as disabling
    /// `UIViewControllerRepresentable`'s from being used.
    @inlinable
    public func ignoreHostingConfigurationConstraints() -> some View {
        modifier(IgnoreHostingConfigurationConstraintsModifier())
    }
}

#endif
