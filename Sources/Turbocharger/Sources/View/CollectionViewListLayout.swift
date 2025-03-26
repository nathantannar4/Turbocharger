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
    public enum Appearance {
        case plain
        case grouped
        case insetGrouped
    }

    public var appearance: Appearance
    public var showsSeparators: Bool

    @inlinable
    public init(
        appearance: Appearance,
        showsSeparators: Bool = false
    ) {
        self.appearance = appearance
        self.showsSeparators = showsSeparators
    }

    #if os(iOS)
    public func makeUICollectionView(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionView {
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
        configuration.headerMode = options.contains(.header) ? .supplementary : .none
        configuration.footerMode = options.contains(.footer) ? .supplementary : .none
        configuration.showsSeparators = showsSeparators
        configuration.backgroundColor = .clear
        if #available(iOS 15.0, *) {
            configuration.headerTopPadding = 0
        }
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)

        let uiCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        uiCollectionView.clipsToBounds = false
        uiCollectionView.keyboardDismissMode = .interactive
        return uiCollectionView
    }

    public func updateUICollectionView(
        _ collectionView: UICollectionView,
        context: Context
    ) { }
    #endif
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionViewLayout where Self == CollectionViewListLayout {

    public static var plain: CollectionViewListLayout { .init(appearance: .plain) }

    public static var grouped: CollectionViewListLayout { .init(appearance: .grouped) }

    public static var insetGrouped: CollectionViewListLayout { .init(appearance: .insetGrouped, showsSeparators: true) }
}



// MARK: - Previews

#if os(iOS)
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CollectionViewListLayout_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            CollectionView(
                .plain,
                sections: [[1, 2], [3]],
                id: \.self
            ) { id in
                CellView("Cell \(id)")
            } header: { _ in
                HeaderFooter()
            } footer: { _ in
                HeaderFooter()
            }

            CollectionView(
                .grouped,
                sections: [[1, 2], [3]],
                id: \.self
            ) { id in
                CellView("Cell \(id)")
            } header: { _ in
                HeaderFooter()
            } footer: { _ in
                HeaderFooter()
            }

            CollectionView(
                .insetGrouped,
                sections: [[1, 2], [3]],
                id: \.self
            ) { id in
                CellView("Cell \(id)")
            } header: { _ in
                HeaderFooter()
            } footer: { _ in
                HeaderFooter()
            }
        }
    }

    struct CellView: View {
        var text: String
        init(_ text: String) {
            self.text = text
        }

        var body: some View {
            Text(text)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
        }
    }

    struct HeaderFooter: View {
        var body: some View {
            Text("Header/Footer")
                .frame(maxWidth: .infinity)
                .background(Color.blue)
        }
    }
}
#endif
