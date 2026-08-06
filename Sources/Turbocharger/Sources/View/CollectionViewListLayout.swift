//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)

import UIKit
import SwiftUI
import Engine

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public enum CollectionViewListLayoutAppearance: Equatable {

    case plain
    case grouped

    @available(tvOS, unavailable)
    case insetGrouped

    @available(tvOS, unavailable)
    case sidebar

    @available(tvOS, unavailable)
    case sidebarPlain

    func toUIKit() -> UICollectionLayoutListConfiguration.Appearance {
        switch self {
        case .plain:
            return .plain
        case .grouped:
            return .grouped
        case .insetGrouped:
            #if os(tvOS)
            return .plain
            #else
            return .insetGrouped
            #endif
        case .sidebar:
            #if os(tvOS)
            return .plain
            #else
            return .sidebar
            #endif
        case .sidebarPlain:
            #if os(tvOS)
            return .plain
            #else
            return .sidebarPlain
            #endif
        }
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct CollectionViewListLayoutSeparatorConfiguration: Equatable {

    @frozen
    public enum Visibility: Equatable {
        case automatic
        case visible
        case hidden

        @available(iOS 14.5, *)
        @available(tvOS, unavailable)
        func toUIKit() -> UIListSeparatorConfiguration.Visibility {
            switch self {
            case .automatic:
                return .automatic
            case .visible:
                return .visible
            case .hidden:
                return .hidden
            }
        }
    }

    public var topSeparatorVisibility: Visibility
    public var bottomSeparatorVisibility: Visibility
    public var topSeparatorInsets: EdgeInsets?
    public var bottomSeparatorInsets: EdgeInsets?
    public var color: Color?

    @available(tvOS, unavailable)
    public init(
        topSeparatorVisibility: Visibility = .automatic,
        bottomSeparatorVisibility: Visibility = .automatic,
        topSeparatorInsets: EdgeInsets? = nil,
        bottomSeparatorInsets: EdgeInsets? = nil,
        color: Color? = nil
    ) {
        self.topSeparatorVisibility = topSeparatorVisibility
        self.bottomSeparatorVisibility = bottomSeparatorVisibility
        self.topSeparatorInsets = topSeparatorInsets
        self.bottomSeparatorInsets = bottomSeparatorInsets
        self.color = color
    }

    @available(iOS 14.5, *)
    @available(tvOS, unavailable)
    func toUIKit(
        appearance: UICollectionLayoutListConfiguration.Appearance,
        in environment: EnvironmentValues
    ) -> UIListSeparatorConfiguration {
        var configuration = UIListSeparatorConfiguration(listAppearance: appearance)
        configuration.topSeparatorVisibility = topSeparatorVisibility.toUIKit()
        configuration.bottomSeparatorVisibility = bottomSeparatorVisibility.toUIKit()
        if let topSeparatorInsets {
            configuration.topSeparatorInsets = NSDirectionalEdgeInsets(topSeparatorInsets)
        }
        if let bottomSeparatorInsets {
            configuration.bottomSeparatorInsets = NSDirectionalEdgeInsets(bottomSeparatorInsets)
        }
        if let color = color?.toUIColor(in: environment) {
            configuration.color = color
        }
        return configuration
    }
}

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct CollectionViewListLayout: CollectionViewLayout {

    public struct Configuration: Equatable {
        public var appearance: CollectionViewListLayoutAppearance
        #if os(iOS) || os(visionOS)
        public var showsSeparators: Bool
        public var separatorConfiguration: CollectionViewListLayoutSeparatorConfiguration?
        #endif
        public var headerTopPadding: CGFloat?
        public var backgroundColor: Color?
        #if os(iOS) || os(visionOS)
        public var leadingSwipeActionsConfiguration: AnyCollectionViewCellSwipeActionsConfiguration?
        public var trailingSwipeActionsConfiguration: AnyCollectionViewCellSwipeActionsConfiguration?
        #endif
    }

    public var configuration: Configuration
    public var backgroundConfiguration: AnyCollectionViewBackgroundConfiguration?

    #if os(iOS) || os(visionOS)
    public init(
        appearance: CollectionViewListLayoutAppearance,
        showsSeparators: Bool,
        separatorConfiguration: CollectionViewListLayoutSeparatorConfiguration? = nil,
        backgroundColor: Color? = nil,
        headerTopPadding: CGFloat? = nil
    ) {
        self.configuration = Configuration(
            appearance: appearance,
            showsSeparators: showsSeparators,
            separatorConfiguration: separatorConfiguration,
            headerTopPadding: headerTopPadding,
            backgroundColor: backgroundColor
        )
    }
    #else
    public init(
        appearance: CollectionViewListLayoutAppearance,
        backgroundColor: Color? = nil,
        headerTopPadding: CGFloat? = nil
    ) {
        self.configuration = Configuration(
            appearance: appearance,
            headerTopPadding: headerTopPadding,
            backgroundColor: backgroundColor
        )
    }
    #endif

    public func makeConfiguration(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionLayoutListConfiguration {
        var layoutConfiguration = configuration.toUIKit(context: context)
        layoutConfiguration.headerMode = options.supplementaryViews.contains(where: { $0.id == .header }) ? .supplementary : .none
        layoutConfiguration.footerMode = options.supplementaryViews.contains(where: { $0.id == .footer }) ? .supplementary : .none
        return layoutConfiguration
    }

    public func makeUICollectionViewLayout(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionViewCompositionalLayout {
        let configuration = makeConfiguration(context: context, options: options)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        return layout
    }

    public func updateUICollectionViewLayout(
        _ collectionViewLayout: UICollectionViewCompositionalLayout,
        context: Context,
        options: CollectionViewLayoutOptions
    ) {
        let configuration = makeConfiguration(context: context, options: options)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        collectionViewLayout.configuration = layout.configuration
    }

    public func makeUICollectionView(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionView {

        let layout = makeUICollectionViewLayout(context: context, options: options)
        let uiCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        uiCollectionView.clipsToBounds = false
        #if os(iOS)
        uiCollectionView.keyboardDismissMode = .interactive
        #endif
        return uiCollectionView
    }

    public func updateUICollectionView(
        _ collectionView: UICollectionView,
        context: Context
    ) {
    }

    public func updateUICollectionViewCell(
        _ collectionView: UICollectionView,
        cell: UICollectionViewCell,
        indexPath: IndexPath,
        context: Context
    ) {
        if let backgroundConfiguration = backgroundConfiguration {
            let configuration = backgroundConfiguration.makeConfiguration(
                for: .item,
                indexPath: indexPath,
                state: cell.configurationState,
                context: context
            )
            cell.backgroundConfiguration = configuration
        } else {
            if #available(iOS 18.0, tvOS 18.0, visionOS 2.0, *) {
                switch configuration.appearance {
                case .sidebar:
                    #if !os(tvOS)
                    cell.backgroundConfiguration = .listAccompaniedSidebarCell()
                    #endif
                default:
                    cell.backgroundConfiguration = .listCell()
                }
            } else {
                switch configuration.appearance {
                case .plain:
                    cell.backgroundConfiguration = .listPlainCell()
                case .grouped:
                    cell.backgroundConfiguration = .listGroupedCell()
                case .insetGrouped:
                    #if !os(tvOS)
                    cell.backgroundConfiguration = .listGroupedCell()
                    #endif
                case .sidebar:
                    #if !os(tvOS)
                    cell.backgroundConfiguration = .listAccompaniedSidebarCell()
                    #endif
                case .sidebarPlain:
                    #if !os(tvOS)
                    cell.backgroundConfiguration = .listSidebarCell()
                    #endif
                }
            }
        }
    }

    public func updateUICollectionViewSupplementaryView(
        _ collectionView: UICollectionView,
        supplementaryView: UICollectionViewCell,
        kind: String,
        indexPath: IndexPath,
        context: Context
    ) {
        if let backgroundConfiguration = backgroundConfiguration {
            let kind = CollectionViewLayoutElementKind.supplementaryView(.custom(kind))
            if #available(iOS 15.0, tvOS 15.0, *) {
                supplementaryView.configurationUpdateHandler = { cell, state in
                    let configuration = backgroundConfiguration.makeConfiguration(
                        for: kind,
                        indexPath: indexPath,
                        state: state,
                        context: context
                    )
                    cell.backgroundConfiguration = configuration
                }
            } else {
                let configuration = backgroundConfiguration.makeConfiguration(
                    for: kind,
                    indexPath: indexPath,
                    state: supplementaryView.configurationState,
                    context: context
                )
                supplementaryView.backgroundConfiguration = configuration
            }
        } else {
            if #available(iOS 18.0, tvOS 18.0, visionOS 2.0, *) {
                switch kind {
                case UICollectionView.elementKindSectionHeader:
                    supplementaryView.backgroundConfiguration = .listHeader()
                case UICollectionView.elementKindSectionFooter:
                    supplementaryView.backgroundConfiguration = .listFooter()
                default:
                    supplementaryView.backgroundConfiguration = .clear()
                }
            } else if kind == UICollectionView.elementKindSectionHeader || kind == UICollectionView.elementKindSectionFooter {
                switch configuration.appearance {
                case .plain:
                    supplementaryView.backgroundConfiguration = .listPlainHeaderFooter()
                case .grouped, .insetGrouped:
                    supplementaryView.backgroundConfiguration = .listGroupedHeaderFooter()
                case .sidebar:
                    #if !os(tvOS)
                    supplementaryView.backgroundConfiguration = .listSidebarHeader()
                    #endif
                case .sidebarPlain:
                    supplementaryView.backgroundConfiguration = .listPlainHeaderFooter()
                }
            } else {
                supplementaryView.backgroundConfiguration = .clear()
            }
        }
    }
}

@available(iOS 14.0, tvOS 14.0, *)
extension CollectionViewListLayout {

    @available(tvOS, unavailable)
    public func showsSeparators(
        _ showsSeparators: Bool
    ) -> CollectionViewListLayout {
        var copy = self
        #if os(iOS) || os(visionOS)
        copy.configuration.showsSeparators = showsSeparators
        #endif
        return copy
    }

    @available(tvOS, unavailable)
    public func separatorConfiguration(
        _ configuration: CollectionViewListLayoutSeparatorConfiguration
    ) -> CollectionViewListLayout {
        var copy = self
        #if os(iOS) || os(visionOS)
        copy.configuration.separatorConfiguration = configuration
        #endif
        return copy
    }

    public func backgroundColor(
        _ color: Color?
    ) -> CollectionViewListLayout {
        var copy = self
        copy.configuration.backgroundColor = color
        return copy
    }

    public func backgroundConfiguration<
        Configuration: CollectionViewBackgroundConfiguration
    >(
        _ configuration: Configuration
    ) -> CollectionViewListLayout {
        var copy = self
        copy.backgroundConfiguration = AnyCollectionViewBackgroundConfiguration(configuration)
        return copy
    }

    @available(tvOS, unavailable)
    public func leadingSwipeActionsConfiguration<
        Configuration: CollectionViewCellSwipeActionsConfiguration
    >(
        _ configuration: Configuration
    ) -> CollectionViewListLayout {
        var copy = self
        #if os(iOS) || os(visionOS)
        copy.configuration.leadingSwipeActionsConfiguration = AnyCollectionViewCellSwipeActionsConfiguration(configuration)
        #endif
        return copy
    }

    @available(tvOS, unavailable)
    public func trailingSwipeActionsConfiguration<
        Configuration: CollectionViewCellSwipeActionsConfiguration
    >(
        _ configuration: Configuration
    ) -> CollectionViewListLayout {
        var copy = self
        #if os(iOS) || os(visionOS)
        copy.configuration.trailingSwipeActionsConfiguration = AnyCollectionViewCellSwipeActionsConfiguration(configuration)
        #endif
        return copy
    }
}

@available(iOS 14.0, tvOS 14.0, *)
extension CollectionViewLayout where Self == CollectionViewListLayout {

    public static var plain: CollectionViewListLayout {
        #if os(iOS) || os(visionOS)
        CollectionViewListLayout(
            appearance: .plain,
            showsSeparators: false,
            backgroundColor: .clear,
            headerTopPadding: 0
        )
        #else
        CollectionViewListLayout(
            appearance: .plain,
            backgroundColor: .clear,
            headerTopPadding: 0
        )
        #endif
    }

    public static var grouped: CollectionViewListLayout {
        #if os(iOS) || os(visionOS)
        CollectionViewListLayout(
            appearance: .grouped,
            showsSeparators: true
        )
        #else
        CollectionViewListLayout(
            appearance: .grouped
        )
        #endif
    }

    @available(tvOS, unavailable)
    public static var insetGrouped: CollectionViewListLayout {
        #if os(iOS) || os(visionOS)
        CollectionViewListLayout(
            appearance: .insetGrouped,
            showsSeparators: true
        )
        #else
        CollectionViewListLayout(
            appearance: .insetGrouped
        )
        #endif
    }

    @available(tvOS, unavailable)
    public static var sidebar: CollectionViewListLayout {
        #if os(iOS) || os(visionOS)
        CollectionViewListLayout(
            appearance: .sidebar,
            showsSeparators: true
        )
        #else
        CollectionViewListLayout(
            appearance: .sidebar
        )
        #endif
    }

    @available(tvOS, unavailable)
    public static var sidebarPlain: CollectionViewListLayout {
        #if os(iOS) || os(visionOS)
        CollectionViewListLayout(
            appearance: .sidebarPlain,
            showsSeparators: true
        )
        #else
        CollectionViewListLayout(
            appearance: .sidebarPlain
        )
        #endif
    }
}

@available(iOS 14.0, tvOS 14.0, *)
extension CollectionViewListLayout.Configuration {

    @MainActor
    func toUIKit(
        context: CollectionViewLayoutContext
    ) -> UICollectionLayoutListConfiguration {
        var layoutConfiguration = UICollectionLayoutListConfiguration(appearance: appearance.toUIKit())
        if #available(iOS 15.0, tvOS 15.0, *) {
            layoutConfiguration.headerTopPadding = headerTopPadding
        }
        layoutConfiguration.backgroundColor = backgroundColor?.toUIColor(in: context.environment)
        #if !os(tvOS)
        layoutConfiguration.showsSeparators = showsSeparators
        if #available(iOS 14.5, *), let separatorConfiguration = separatorConfiguration {
            layoutConfiguration.separatorConfiguration = separatorConfiguration.toUIKit(appearance: layoutConfiguration.appearance, in: context.environment)
        }
        layoutConfiguration.leadingSwipeActionsConfigurationProvider = leadingSwipeActionsConfiguration.map { configuration in
            return { indexPath in
                configuration.makeConfiguration(
                    indexPath: indexPath,
                    context: context
                )
            }
        }
        layoutConfiguration.trailingSwipeActionsConfigurationProvider = trailingSwipeActionsConfiguration.map { configuration in
            return { indexPath in
                configuration.makeConfiguration(
                    indexPath: indexPath,
                    context: context
                )
            }
        }
        #endif
        return layoutConfiguration
    }
}

// MARK: - Previews

@available(iOS 15.0, tvOS 15.0, *)
struct CollectionViewListLayout_Previews: PreviewProvider {

    struct SwipeActions: CollectionViewCellSwipeActionsConfiguration {

        #if os(iOS) || os(visionOS)
        func makeConfiguration(
            indexPath: IndexPath,
            context: Context
        ) -> UISwipeActionsConfiguration {
            let action = UIContextualAction(
                style: .normal,
                title: "Action",
                handler: { action, view, block in
                    block(true)
                }
            )
            let configuration = UISwipeActionsConfiguration(
                actions: [
                    action
                ]
            )
            configuration.performsFirstActionWithFullSwipe = true
            return configuration
        }
        #endif
    }

    static var previews: some View {
        #if os(iOS) || os(visionOS)
        ZStack {
            CollectionView(
                .plain.showsSeparators(true).trailingSwipeActionsConfiguration(SwipeActions()),
                sections: [
                    CollectionViewSection(items: [1, 2], id: \.self, section: 0),
                    CollectionViewSection(items: [3, 4], id: \.self, section: 1),
                ]
            ) { indexPath, section, id in
                CellView("Cell \(id.value)")
            } header: { _, _ in
                HeaderFooter()
            } footer: { _, _ in
                HeaderFooter()
            }
            .onSelect(action: { _, item in
                print("Selected \(item.value)")
            })
            .ignoresSafeArea()
        }
        #endif

        ZStack {
            CollectionView(
                .grouped,
                sections: [
                    CollectionViewSection(items: [1, 2], id: \.self, section: 0),
                    CollectionViewSection(items: [3], id: \.self, section: 1),
                ]
            ) { indexPath, section, id in
                CellView("Cell \(id.value)")
            } header: { _, _ in
                HeaderFooter()
            } footer: { _, _ in
                HeaderFooter()
            }
            .onSelect(action: { _, item in
                print("Selected \(item.value)")
            })
            .background(Color.blue.opacity(0.3))
            .ignoresSafeArea()
        }

        #if os(iOS) || os(visionOS)
        ZStack {
            CollectionView(
                .insetGrouped,
                sections: [
                    CollectionViewSection(items: [1, 2], id: \.self, section: 0),
                    CollectionViewSection(items: [3], id: \.self, section: 1),
                ]
            ) { indexPath, section, id in
                CellView("Cell \(id.value)")
            } header: { _, _ in
                HeaderFooter()
            } footer: { _, _ in
                HeaderFooter()
            }
            .onSelect(action: { _, item in
                print("Selected \(item.value)")
            })
            .background(Color.blue.opacity(0.3))
            .ignoresSafeArea()
        }
        #endif

        ZStack {
            CollectionView(
                .plain,
                sections: [
                    CollectionViewSection(items: [1, 2, 3], id: \.self, section: 0)
                ]
            ) { indexPath, section, id in
                ExpandableView {
                    CellView("Cell \(id.value)")
                }
            } header: { _, _ in
                ExpandableView {
                    Text("Header/Footer")
                        .padding(.horizontal)
                }
            } footer: { _, _ in
                ExpandableView {
                    Text("Header/Footer")
                        .padding(.horizontal)
                }
            }
            .onSelect(action: { _, item in
                print("Selected \(item.value)")
            })
        }
    }

    struct ExpandableView<Content: View>: View {
        var content: Content

        @State var isExpanded = false

        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        var body: some View {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                content
                    .frame(minHeight: isExpanded ? 88 : 44)
            }
        }
    }

    struct CellView: View {
        var text: String
        init(_ text: String) {
            self.text = text
        }

        var body: some View {
            HStack {
                Image(systemName: "square.fill")
                    .foregroundColor(.secondary)

                Text(text)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    struct HeaderFooter: View {
        var body: some View {
            Text("Header/Footer")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

#endif
