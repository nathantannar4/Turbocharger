//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

#if os(iOS)

@available(iOS 14.0, *)
@MainActor @preconcurrency
public protocol CollectionViewRepresentable: View {

    associatedtype Layout: CollectionViewLayout
    associatedtype Section: Equatable & Identifiable where Section.ID: Sendable
    associatedtype Items: RandomAccessCollection where Items.Index: Hashable & Sendable, Items.Element: Equatable & Identifiable, Items.Element.ID: Sendable
    associatedtype Coordinator: CollectionViewCoordinator<Layout, Section, Items>

    var layout: Layout { get }
    var sections: [CollectionViewSection<Section, Items>] { get }

    func updateCoordinator(_ coordinator: Coordinator)

    func makeCoordinator() -> Coordinator
}

@available(iOS 14.0, *)
extension CollectionViewRepresentable where Body == _CollectionViewRepresentableBody<Self> {

    public var body: _CollectionViewRepresentableBody<Self> {
        _CollectionViewRepresentableBody(representable: self)
    }
}

@frozen
@available(iOS 14.0, *)
public struct _CollectionViewRepresentableBody<Representable: CollectionViewRepresentable>: UIViewRepresentable {

    public typealias Coordinator = Representable.Coordinator
    public typealias UIViewType = Representable.Layout.UICollectionViewType

    var representable: Representable

    public func makeUIView(context: Context) -> UIViewType {
        context.coordinator.context = CollectionViewLayoutContext(
            environment: context.environment,
            transaction: context.transaction
        )
        let uiView = representable.layout.makeUICollectionView(
            context: context.coordinator.context,
            options: context.coordinator.layoutOptions
        )
        context.coordinator.configure(to: uiView)

        return uiView
    }

    public func updateUIView(_ uiView: UIViewType, context: Context) {
        context.coordinator.context = CollectionViewLayoutContext(
            environment: context.environment,
            transaction: context.transaction
        )
        representable.updateCoordinator(context.coordinator)
        let shouldInvalidateLayout = representable.layout.shouldInvalidateLayout(
            from: context.coordinator.layout,
            context: context.coordinator.context,
            options: context.coordinator.layoutOptions
        )
        context.coordinator.update(layout: representable.layout)
        if shouldInvalidateLayout {
            let layout = representable.layout.makeUICollectionViewLayout(
                context: context.coordinator.context,
                options: context.coordinator.layoutOptions
            )
            uiView.setCollectionViewLayout(
                layout,
                animated: context.coordinator.context.transaction.isAnimated
            )
        }
        context.coordinator.update(sections: representable.sections)
    }

    public func makeCoordinator() -> Coordinator {
        representable.makeCoordinator()
    }

    public func _overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: _ProposedSize,
        uiView: UIViewType
    ) {
        let proposedSize = ProposedSize(proposedSize)
        representable.layout.overrideSizeThatFits(
            &size,
            in: proposedSize,
            collectionView: uiView
        )
    }
}

#endif
