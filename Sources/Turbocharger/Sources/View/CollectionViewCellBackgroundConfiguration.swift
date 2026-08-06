//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)

import UIKit
import SwiftUI
import Engine

@available(iOS 14.0, tvOS 14.0, *)
public protocol CollectionViewBackgroundConfiguration: Equatable {

    @MainActor @preconcurrency func makeConfiguration(
        for kind: CollectionViewLayoutElementKind,
        indexPath: IndexPath,
        state: UICellConfigurationState,
        context: Context
    ) -> UIBackgroundConfiguration

    typealias Context = CollectionViewLayoutContext
}

@available(iOS 14.0, tvOS 14.0, *)
extension CollectionViewBackgroundConfiguration where Self == CollectionViewListBackgroundConfiguration {

    public static var list: CollectionViewListBackgroundConfiguration { .init() }

    public static func list(
        cornerRadius: CGFloat? = nil,
        backgroundColor: Color? = nil,
        highlightedBackgroundColor: Color? = nil
    ) -> CollectionViewListBackgroundConfiguration {
        CollectionViewListBackgroundConfiguration(
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            highlightedBackgroundColor: highlightedBackgroundColor
        )
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct CollectionViewListBackgroundConfiguration: CollectionViewBackgroundConfiguration {

    public var cornerRadius: CGFloat?
    public var backgroundColor: Color?
    public var highlightedBackgroundColor: Color?

    @inlinable
    public init(
        cornerRadius: CGFloat? = nil,
        backgroundColor: Color? = nil,
        highlightedBackgroundColor: Color? = nil
    ) {
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.highlightedBackgroundColor = highlightedBackgroundColor
    }

    public func makeConfiguration(
        for kind: CollectionViewLayoutElementKind,
        indexPath: IndexPath,
        state: UICellConfigurationState,
        context: Context
    ) -> UIBackgroundConfiguration {
        var configuration: UIBackgroundConfiguration
        if #available(iOS 18.0, tvOS 18.0, visionOS 2.0, *) {
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
        if let cornerRadius {
            configuration.cornerRadius = cornerRadius
        }
        if state.isHighlighted || state.isSelected, let highlightedBackgroundColor {
            configuration.backgroundColor = highlightedBackgroundColor.toUIColor()
        } else if let backgroundColor {
            configuration.backgroundColor = backgroundColor.toUIColor()
        }
        return configuration
    }
}

@available(iOS 14.0, tvOS 14.0, *)
extension CollectionViewBackgroundConfiguration where Self == CollectionViewPlainBackgroundConfiguration {

    public static var plain: CollectionViewPlainBackgroundConfiguration { .init() }

    public static func plain(
        cornerRadius: CGFloat? = nil,
        backgroundColor: Color? = nil,
        highlightedBackgroundColor: Color? = nil
    ) -> CollectionViewPlainBackgroundConfiguration {
        CollectionViewPlainBackgroundConfiguration(
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            highlightedBackgroundColor: highlightedBackgroundColor
        )
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct CollectionViewPlainBackgroundConfiguration: CollectionViewBackgroundConfiguration {

    public var cornerRadius: CGFloat?
    public var backgroundColor: Color?
    public var highlightedBackgroundColor: Color?

    @inlinable
    public init(
        cornerRadius: CGFloat? = nil,
        backgroundColor: Color? = nil,
        highlightedBackgroundColor: Color? = nil
    ) {
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.highlightedBackgroundColor = highlightedBackgroundColor
    }

    public func makeConfiguration(
        for kind: CollectionViewLayoutElementKind,
        indexPath: IndexPath,
        state: UICellConfigurationState,
        context: Context
    ) -> UIBackgroundConfiguration {
        var configuration = UIBackgroundConfiguration.clear()
        if let cornerRadius {
            configuration.cornerRadius = cornerRadius
        }
        if state.isHighlighted || state.isSelected, let highlightedBackgroundColor {
            configuration.backgroundColor = highlightedBackgroundColor.toUIColor()
        } else if let backgroundColor {
            configuration.backgroundColor = backgroundColor.toUIColor()
        }
        return configuration
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct AnyCollectionViewBackgroundConfiguration: CollectionViewBackgroundConfiguration {

    @usableFromInline
    var storage: AnyCollectionViewBackgroundConfigurationStorageBase

    public init<Configuration: CollectionViewBackgroundConfiguration>(_ configuration: Configuration) {
        storage = AnyCollectionViewBackgroundConfigurationStorage(configuration)
    }

    public func makeConfiguration(
        for kind: CollectionViewLayoutElementKind,
        indexPath: IndexPath,
        state: UICellConfigurationState,
        context: Context
    ) -> UIBackgroundConfiguration {
        storage.makeConfiguration(for: kind, indexPath: indexPath, state: state, context: context)
    }

    public static func == (
        lhs: AnyCollectionViewBackgroundConfiguration,
        rhs: AnyCollectionViewBackgroundConfiguration
    ) -> Bool {
        lhs.storage.isEqual(to: rhs.storage)
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@usableFromInline
class AnyCollectionViewBackgroundConfigurationStorageBase {

    @MainActor @preconcurrency
    func makeConfiguration(
        for kind: CollectionViewLayoutElementKind,
        indexPath: IndexPath,
        state: UICellConfigurationState,
        context: Context
    ) -> UIBackgroundConfiguration {
        fatalError("base")
    }

    func isEqual(to other: AnyCollectionViewBackgroundConfigurationStorageBase) -> Bool {
        fatalError("base")
    }

    typealias Context = CollectionViewLayoutContext
}

@available(iOS 14.0, tvOS 14.0, *)
@usableFromInline
final class AnyCollectionViewBackgroundConfigurationStorage<
    Configuration: CollectionViewBackgroundConfiguration
>: AnyCollectionViewBackgroundConfigurationStorageBase {

    let configuration: Configuration

    init(_ configuration: Configuration) {
        self.configuration = configuration
    }

    override func makeConfiguration(
        for kind: CollectionViewLayoutElementKind,
        indexPath: IndexPath,
        state: UICellConfigurationState,
        context: Context
    ) -> UIBackgroundConfiguration {
        configuration.makeConfiguration(for: kind, indexPath: indexPath, state: state, context: context)
    }

    override func isEqual(to other: AnyCollectionViewBackgroundConfigurationStorageBase) -> Bool {
        guard let other = other as? AnyCollectionViewBackgroundConfigurationStorage<Configuration> else {
            return false
        }
        return configuration == other.configuration
    }
}

// MARK: - Previews

@available(iOS 14.0, tvOS 14.0, *)
struct CollectionViewBackgroundConfiguration_Previews: PreviewProvider {

    static var previews: some View {
        PreviewA()
        PreviewB()
    }

    struct PreviewA: View {
        @State var flag = false

        var body: some View {
            CollectionView(
                .compositional(
                    contentInsets: EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
                )
                .backgroundConfiguration(
                    .plain(
                        cornerRadius: 8,
                        highlightedBackgroundColor: .accentColor
                    )
                )
            ) {
                ForEach(100) {
                    Text("Hello, World")
                        .frame(minHeight: 44)
                }
            }
            .onSelect(action: { _, _ in
                print("selected")
            })
            .ignoresSafeArea()
        }
    }

    struct PreviewB: View {
        struct BackgroundConfiguration: CollectionViewBackgroundConfiguration {
            var color: Color

            func makeConfiguration(
                for kind: CollectionViewLayoutElementKind,
                indexPath: IndexPath,
                state: UICellConfigurationState,
                context: Context
            ) -> UIBackgroundConfiguration {
                var configuration = UIBackgroundConfiguration.clear()
                configuration.backgroundColor = color.toUIColor(in: context.environment)
                return configuration
            }
        }

        @State var flag = false

        var body: some View {
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
            .overlay(alignment: .bottom) {
                Toggle(isOn: $flag) {
                    Text("flag")
                }
            }
        }
    }
}
#endif
