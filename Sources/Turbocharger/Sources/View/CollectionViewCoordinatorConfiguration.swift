//
// Copyright (c) Nathan Tannar
//

#if os(iOS) || os(tvOS) || os(visionOS)

import UIKit
import SwiftUI
import Engine

@available(iOS 14.0, tvOS 14.0, *)
public protocol CollectionViewCoordinatorConfiguration {

    associatedtype Item: Equatable & Identifiable

    associatedtype ReuseIdentifier: Hashable

    static func reuseIdentifier(for item: Item) -> ReuseIdentifier

    static var reuseIdentifiers: Set<ReuseIdentifier> { get }
}

@available(iOS 14.0, tvOS 14.0, *)
@frozen
public struct CollectionViewCoordinatorDefaultConfiguration<
    Item: Equatable & Identifiable
>: CollectionViewCoordinatorConfiguration {

    public struct ReuseIdentifier: Hashable { }

    @inlinable
    public init() { }

    public static func reuseIdentifier(for item: Item) -> ReuseIdentifier {
        return ReuseIdentifier()
    }

    public static var reuseIdentifiers: Set<ReuseIdentifier> { [ReuseIdentifier()] }
}

// MARK: - Previews

@available(iOS 14.0, tvOS 14.0, *)
struct CollectionViewCoordinatorConfiguration_Previews: PreviewProvider {

    enum PreviewItem: Equatable, Identifiable {

        enum Kind: Hashable, CaseIterable {
            case number
            case text
        }

        struct NumberItem: Equatable, Identifiable {
            var id = UUID()
            var int: Int
        }
        case number(NumberItem)

        struct TextItem: Equatable, Identifiable {
            var id = UUID()
            var string: String
        }
        case text(TextItem)

        var id: UUID {
            switch self {
            case .number(let item):
                return item.id
            case .text(let item):
                return item.id
            }
        }

        var kind: Kind {
            switch self {
            case .number:
                return .number
            case .text:
                return .text
            }
        }

        static let items: [PreviewItem] = [
            .number(.init(int: 42)),
            .text(.init(string: "Hello, World"))
        ]
    }

    struct PreviewConfiguration: CollectionViewCoordinatorConfiguration {

        static func reuseIdentifier(for item: PreviewItem) -> PreviewItem.Kind {
            return item.kind
        }

        static var reuseIdentifiers: Set<PreviewItem.Kind> { Set(PreviewItem.Kind.allCases) }
    }

    static var previews: some View {
        ZStack {
            CollectionView(
                .compositional,
                items: PreviewItem.items,
                options: .useReusableHostingConfiguration,
                configuration: PreviewConfiguration()
            ) { indexPath, section, item in
                switch item {
                case .number(let item):
                    Text(item.int.description)
                case .text(let item):
                    Text(item.string)
                }
            }
        }
    }
}

#endif
