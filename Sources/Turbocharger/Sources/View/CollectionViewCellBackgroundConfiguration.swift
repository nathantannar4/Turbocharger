//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

#if os(iOS)
import UIKit
#endif

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol CollectionViewBackgroundConfiguration: Equatable, Sendable {

    #if os(iOS)
    @MainActor @preconcurrency func makeConfiguration(
        for kind: CollectionViewLayoutElementKind,
        state: UICellConfigurationState
    ) -> UIBackgroundConfiguration
    #endif
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionViewBackgroundConfiguration where Self == CollectionViewSelectableBackgroundConfiguration {
    public static var selectable: CollectionViewSelectableBackgroundConfiguration { .init() }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct CollectionViewSelectableBackgroundConfiguration: CollectionViewBackgroundConfiguration {

    #if os(iOS)
    @MainActor @preconcurrency public func makeConfiguration(
        for kind: CollectionViewLayoutElementKind,
        state: UICellConfigurationState
    ) -> UIBackgroundConfiguration {
        let configuration: UIBackgroundConfiguration
        if #available(iOS 18.0, *) {
            switch kind {
            case .item:
                configuration = UIBackgroundConfiguration.listCell()
            case .supplementaryView(let id):
                switch id {
                case .header:
                    configuration = UIBackgroundConfiguration.listHeader()
                case .footer:
                    configuration = UIBackgroundConfiguration.listFooter()
                case .custom:
                    configuration = UIBackgroundConfiguration.listCell()
                }
            }
        } else {
            switch kind {
            case .item:
                configuration = UIBackgroundConfiguration.listPlainCell()
            case .supplementaryView(let id):
                switch id {
                case .header, .footer:
                    configuration = UIBackgroundConfiguration.listPlainHeaderFooter()
                case .custom:
                    configuration = UIBackgroundConfiguration.listPlainCell()
                }
            }
        }
        return configuration
    }
    #endif
}

// MARK: - Previews

#if os(iOS)
@available(iOS 14.0, *)
struct CollectionViewBackgroundConfiguration_Previews: PreviewProvider {

    struct BackgroundConfiguration: CollectionViewBackgroundConfiguration {
        var color: Color

        func makeConfiguration(
            for kind: CollectionViewLayoutElementKind,
            state: UICellConfigurationState
        ) -> UIBackgroundConfiguration {
            var configuration = UIBackgroundConfiguration.clear()
            configuration.backgroundColor = color.toUIColor()
            return configuration
        }
    }

    static var previews: some View {
        ZStack {
            StateAdapter(initialValue: false) { $flag in
                CollectionView(
                    .compositional.backgroundConfiguration(
                        BackgroundConfiguration(color: flag ? .blue : .red)
                    )
                ) {
                    ForEach(100) {
                        Text("Hello, World")
                            .foregroundColor(.white)
                            .frame(minHeight: 44)
                    }
                }
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        flag.toggle()
                    }
                }
            }
        }
    }
}
#endif
