//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

#if os(iOS)

@available(iOS 14.0, *)
@MainActor @preconcurrency
public protocol CollectionViewRepresentable: View {

    associatedtype Data: RandomAccessCollection where Data.Element: RandomAccessCollection, Data.Index: Hashable, Data.Element.Element: Equatable & Identifiable
    associatedtype Layout: CollectionViewLayout
    associatedtype Coordinator: CollectionViewCoordinator<Layout, Data>

    var data: Data { get }
    var layout: Layout { get }

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
        context.coordinator.update(layout: representable.layout)
        representable.updateCoordinator(context.coordinator)
        context.coordinator.update(data: representable.data)
    }

    public func makeCoordinator() -> Coordinator {
        representable.makeCoordinator()
    }
}

#endif
