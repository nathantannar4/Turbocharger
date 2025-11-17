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
    public enum Appearance {
        case plain
        case grouped
        case insetGrouped
    }

    public var appearance: Appearance
    public var showsSeparators: Bool
    public var backgroundColor: Color?
    public var headerTopPadding: CGFloat?

    @inlinable
    public init(
        appearance: Appearance,
        showsSeparators: Bool,
        backgroundColor: Color? = nil,
        headerTopPadding: CGFloat? = nil
    ) {
        self.appearance = appearance
        self.showsSeparators = showsSeparators
        self.backgroundColor = backgroundColor
        self.headerTopPadding = headerTopPadding
    }

    #if os(iOS)
    public func makeUICollectionViewLayout(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionViewCompositionalLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: {
            switch appearance {
            case .plain:
                return .plain
            case .grouped:
                return .grouped
            case .insetGrouped:
                return .insetGrouped
            }
        }())
        configuration.headerMode = options.supplementaryViews.contains(where: { $0.id == .header }) ? .supplementary : .none
        configuration.footerMode = options.supplementaryViews.contains(where: { $0.id == .footer }) ? .supplementary : .none
        configuration.showsSeparators = showsSeparators
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
            .plain,
            sections: [
                CollectionViewSection(items: [1, 2], id: \.self, section: 0),
                CollectionViewSection(items: [3], id: \.self, section: 1),
            ]
        ) { indexPath, id in
            CellView("Cell \(id.value)")
        } header: { _, _ in
            HeaderFooter()
        } footer: { _, _ in
            HeaderFooter()
        }
        .background(Color.blue.opacity(0.3))
        .ignoresSafeArea()

        CollectionView(
            .grouped,
            sections: [
                CollectionViewSection(items: [1, 2], id: \.self, section: 0),
                CollectionViewSection(items: [3], id: \.self, section: 1),
            ]
        ) { indexPath, id in
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
        ) { indexPath, id in
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
            Text(text)
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
