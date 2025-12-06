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

    @frozen
    public enum Appearance: Equatable, Sendable {
        case plain
        case grouped
        case insetGrouped

        #if os(iOS)
        public func toUIKit() -> UICollectionLayoutListConfiguration.Appearance {
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
            public func toUIKit() -> UIListSeparatorConfiguration.Visibility {
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

    public struct Configuration: Equatable {
        public var appearance: Appearance
        public var showsSeparators: Bool
        public var separatorConfiguration: SeparatorConfiguration?
        public var headerTopPadding: CGFloat?
    }

    public var configuration: Configuration
    public var backgroundColor: Color?
    public var safeAreaInsets: EdgeInsets?

    public init(
        appearance: Appearance,
        showsSeparators: Bool,
        separatorConfiguration: SeparatorConfiguration? = nil,
        backgroundColor: Color? = nil,
        headerTopPadding: CGFloat? = nil,
        safeAreaInsets: EdgeInsets? = nil
    ) {
        self.configuration = Configuration(
            appearance: appearance,
            showsSeparators: showsSeparators,
            separatorConfiguration: separatorConfiguration,
            headerTopPadding: headerTopPadding
        )
        self.backgroundColor = backgroundColor
        self.safeAreaInsets = safeAreaInsets
    }

    #if os(iOS)
    public func makeConfiguration(
        options: CollectionViewLayoutOptions
    ) -> UICollectionLayoutListConfiguration {
        var layoutConfiguration = UICollectionLayoutListConfiguration(appearance: configuration.appearance.toUIKit())
        layoutConfiguration.headerMode = options.supplementaryViews.contains(where: { $0.id == .header }) ? .supplementary : .none
        layoutConfiguration.footerMode = options.supplementaryViews.contains(where: { $0.id == .footer }) ? .supplementary : .none
        layoutConfiguration.showsSeparators = configuration.showsSeparators
        if #available(iOS 14.5, *), let separatorConfiguration = configuration.separatorConfiguration {
            layoutConfiguration.separatorConfiguration = separatorConfiguration.toUIKit(appearance: layoutConfiguration.appearance)
        }
        if #available(iOS 15.0, *) {
            layoutConfiguration.headerTopPadding = configuration.headerTopPadding
        }
        return layoutConfiguration
    }

    public func makeUICollectionViewLayout(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionViewCompositionalLayout {
        let configuration = makeConfiguration(options: options)
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
        uiCollectionView.backgroundColor = backgroundColor?.toUIColor() ?? .clear
        return uiCollectionView
    }

    public func updateUICollectionView(
        _ collectionView: UICollectionView,
        context: Context
    ) {
        let safeAreaInsets = safeAreaInsets.map {
            UIEdgeInsets(
                edgeInsets: $0,
                layoutDirection: context.environment.layoutDirection
            )
        } ?? .zero
        var contentInset = safeAreaInsets
        contentInset.top = max(0, safeAreaInsets.top - collectionView.safeAreaInsets.top)
        contentInset.bottom = max(0, safeAreaInsets.bottom - collectionView.safeAreaInsets.bottom)
        contentInset.left = max(0, safeAreaInsets.left - collectionView.safeAreaInsets.left)
        contentInset.right = max(0, safeAreaInsets.right - collectionView.safeAreaInsets.right)
        if collectionView.contentInset != contentInset {
            collectionView.contentInset = contentInset
            collectionView.scrollIndicatorInsets = contentInset
        }
    }

    public func updateUICollectionViewCell(
        _ collectionView: UICollectionView,
        cell: UICollectionViewCell,
        indexPath: IndexPath,
        context: Context
    ) {
        if #available(iOS 18.0, *) {
            cell.backgroundConfiguration = .listCell()
        } else {
            switch configuration.appearance {
            case .plain:
                cell.backgroundConfiguration = .listPlainCell()
            case .grouped, .insetGrouped:
                cell.backgroundConfiguration = .listGroupedCell()
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
            switch configuration.appearance {
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
        copy.configuration.showsSeparators = showsSeparators
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
    }

    struct ExpandableView<Content: View>: View {
        var content: Content

        @State var isExpanded = false

        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        var body: some View {
            content
                .frame(minHeight: isExpanded ? 88 : 44)
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
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
