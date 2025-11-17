//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct CollectionViewListLayout: CollectionViewLayout {

    #if os(iOS)
    public typealias UICollectionViewCellType = UICollectionViewListCell
    public typealias UICollectionViewSupplementaryViewType = UICollectionViewListCell
    #endif

    @frozen
    public enum Appearance: Equatable, Sendable {
        case plain
        case grouped
        case insetGrouped

        #if os(iOS)
        func toUIKit() -> UICollectionLayoutListConfiguration.Appearance {
            switch self {
            case .plain:
                return .plain
            case .grouped:
                return .grouped
            case .insetGrouped:
                return .insetGrouped
            }
        }
        #endif
    }

    @frozen
    public struct SeparatorConfiguration: Equatable, Sendable {

        @frozen
        public enum Visibility: Equatable, Sendable {
            case automatic
            case visible
            case hidden

            #if os(iOS)
            @available(iOS 14.5, *)
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
            #endif
        }

        public var topSeparatorVisibility: Visibility
        public var bottomSeparatorVisibility: Visibility
        public var topSeparatorInsets: EdgeInsets?
        public var bottomSeparatorInsets: EdgeInsets?
        public var color: Color?

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

        #if os(iOS)
        @available(iOS 14.5, *)
        func toUIKit(
            appearance: UICollectionLayoutListConfiguration.Appearance
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
            if let color = color?.toUIColor() {
                configuration.color = color
            }
            return configuration
        }
        #endif
    }

    public var appearance: Appearance
    public var showsSeparators: Bool
    public var separatorConfiguration: SeparatorConfiguration?
    public var backgroundColor: Color?
    public var headerTopPadding: CGFloat?

    @inlinable
    public init(
        appearance: Appearance,
        showsSeparators: Bool,
        separatorConfiguration: SeparatorConfiguration? = nil,
        backgroundColor: Color? = nil,
        headerTopPadding: CGFloat? = nil
    ) {
        self.appearance = appearance
        self.showsSeparators = showsSeparators
        self.separatorConfiguration = separatorConfiguration
        self.backgroundColor = backgroundColor
        self.headerTopPadding = headerTopPadding
    }

    #if os(iOS)
    public func makeUICollectionViewLayout(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionViewCompositionalLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: appearance.toUIKit())
        configuration.headerMode = options.supplementaryViews.contains(where: { $0.id == .header }) ? .supplementary : .none
        configuration.footerMode = options.supplementaryViews.contains(where: { $0.id == .footer }) ? .supplementary : .none
        configuration.showsSeparators = showsSeparators
        if #available(iOS 14.5, *), let separatorConfiguration {
            configuration.separatorConfiguration = separatorConfiguration.toUIKit(appearance: configuration.appearance)
        }
        configuration.backgroundColor = backgroundColor?.toUIColor()
        if #available(iOS 15.0, *) {
            configuration.headerTopPadding = headerTopPadding
        }
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        return layout
    }

    public func makeUICollectionView(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionView {

        let layout = makeUICollectionViewLayout(context: context, options: options)
        let uiCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        uiCollectionView.clipsToBounds = false
        uiCollectionView.keyboardDismissMode = .interactive
        uiCollectionView.backgroundColor = .clear
        return uiCollectionView
    }

    public func updateUICollectionView(
        _ collectionView: UICollectionView,
        context: Context
    ) { }

    public func updateUICollectionViewCell(
        _ collectionView: UICollectionView,
        cell: UICollectionViewListCell,
        indexPath: IndexPath,
        context: Context
    ) {
        if #available(iOS 18.0, *) {
            cell.backgroundConfiguration = .listCell()
        } else {
            switch appearance {
            case .plain:
                cell.backgroundConfiguration = .listPlainCell()
            case .grouped, .insetGrouped:
                cell.backgroundConfiguration = .listGroupedCell()
            }
        }
    }

    public func updateUICollectionViewSupplementaryView(
        _ collectionView: UICollectionView,
        supplementaryView: UICollectionViewListCell,
        kind: String,
        indexPath: IndexPath,
        context: Context
    ) {
        if #available(iOS 18.0, *) {
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                supplementaryView.backgroundConfiguration = .listHeader()
            case UICollectionView.elementKindSectionFooter:
                supplementaryView.backgroundConfiguration = .listFooter()
            default:
                supplementaryView.backgroundConfiguration = .clear()
            }
        } else {
            switch appearance {
            case .plain:
                supplementaryView.backgroundConfiguration = .listPlainHeaderFooter()
            case .grouped, .insetGrouped:
                supplementaryView.backgroundConfiguration = .listGroupedHeaderFooter()
            }
        }
    }
    #endif
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionViewListLayout {

    public func showsSeparators(
        _ showsSeparators: Bool
    ) -> CollectionViewListLayout {
        var copy = self
        copy.showsSeparators = showsSeparators
        return copy
    }

    public func backgroundColor(
        _ color: Color?
    ) -> CollectionViewListLayout {
        var copy = self
        copy.backgroundColor = color
        return copy
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionViewLayout where Self == CollectionViewListLayout {

    public static var plain: CollectionViewListLayout {
        CollectionViewListLayout(
            appearance: .plain,
            showsSeparators: false,
            backgroundColor: .clear,
            headerTopPadding: 0
        )
    }

    public static var grouped: CollectionViewListLayout {
        CollectionViewListLayout(
            appearance: .grouped,
            showsSeparators: true
        )
    }

    public static var insetGrouped: CollectionViewListLayout {
        CollectionViewListLayout(
            appearance: .insetGrouped,
            showsSeparators: true
        )
    }
}

// MARK: - Previews

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CollectionViewListLayout_Previews: PreviewProvider {
    static var previews: some View {

        CollectionView(
            .plain.showsSeparators(true),
            sections: [
                CollectionViewSection(items: [1, 2], id: \.self, section: 0),
                CollectionViewSection(items: [3], id: \.self, section: 1),
            ]
        ) { indexPath, section, id in
            CellView("Cell \(id.value)")
        } header: { _, _ in
            HeaderFooter()
        } footer: { _, _ in
        }
        .ignoresSafeArea()

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
        .background(Color.blue.opacity(0.3))
        .ignoresSafeArea()

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
        .background(Color.blue.opacity(0.3))
        .ignoresSafeArea()
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
                .background(Material.ultraThin)
        }
    }
}

#endif
