//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)

import UIKit
import SwiftUI
import Engine

@available(iOS 14.0, tvOS 14.0, *)
public struct HostingConfiguration<
    Content: View
>: UIContentConfiguration {

    public var content: Content

    public init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    public func makeContentView() -> UIView & UIContentView {
        return HostingConfigurationHostingView(configuration: self)
    }

    public func updated(for state: UIConfigurationState) -> Self {
        return self
    }
}

@available(iOS 14.0, tvOS 14.0, *)
open class HostingConfigurationHostingView<
    Content: View
>: HostingView<ModifiedContent<Content, HostingConfigurationModifier>>, UIContentView {

    public var configuration: UIContentConfiguration {
        didSet {
            let configuration = configuration as! HostingConfiguration<Content>
            content.content = configuration.content
        }
    }

    public init(configuration: HostingConfiguration<Content>) {
        self.configuration = configuration
        super.init(content: configuration.content.modifier(HostingConfigurationModifier()))
        invalidatesIntrinsicContentSizeOnIdealSizeChange = true
        automaticallyLayoutIntrinsicContentSizeChange = false
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func supports(_ configuration: any UIContentConfiguration) -> Bool {
        return configuration is HostingConfiguration<Content>
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct HostingConfigurationModifier: ViewModifier {

    @inlinable
    public init() { }

    public func body(content: Content) -> some View {
        content
            .input(IsInHostingConfiguration.self)
    }
}

#endif
