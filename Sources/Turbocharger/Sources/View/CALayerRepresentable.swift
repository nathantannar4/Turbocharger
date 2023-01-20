//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

#if !os(watchOS)

/// A wrapper for a QuartzCore layer that you use to integrate that layer into your
/// SwiftUI view hierarchy.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
public protocol CALayerRepresentable: View where Body == Never {
    associatedtype CALayerType: CALayer

    func updateCALayer(_ layer: CALayerType, context: Context)

    associatedtype Coordinator = Void

    func makeCoordinator() -> Coordinator

    static func dismantleCALayer(coordinator: Coordinator)

    typealias Context = CALayerRepresentableContext<Self>
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
extension CALayerRepresentable where Coordinator == Void {
    public func makeCoordinator() -> Coordinator { () }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
extension CALayerRepresentable {
    public static func dismantleCALayer(coordinator: Coordinator) { }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
@frozen
public struct CALayerRepresentableContext<
    Representable: CALayerRepresentable
> {
    public var coordinator: Representable.Coordinator
    public var environment: EnvironmentValues
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
extension CALayerRepresentable {
    public var body: Never {
        bodyError()
    }

    private var content: CALayerRepresentableBody<Self> {
        CALayerRepresentableBody(representable: self)
    }

    public static func _makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        CALayerRepresentableBody<Self>._makeView(view: view[\.content], inputs: inputs)
    }

    public static func _makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        CALayerRepresentableBody<Self>._makeViewList(view: view[\.content], inputs: inputs)
    }

    public static func _viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        CALayerRepresentableBody<Self>._viewListCount(inputs: inputs)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
private struct CALayerRepresentableBody<
    Representable: CALayerRepresentable
>: View {
    var representable: Representable

    @StateObject var coordinator: CoordinatorStorage
    @Environment(\.self) var environment

    init(representable: Representable) {
        self.representable = representable
        self._coordinator = StateObject(
            wrappedValue: CoordinatorStorage(
                coordinator: representable.makeCoordinator()
            )
        )
    }

    var body: some View {
        _CALayerView(type: Representable.CALayerType.self) { layer in
            representable.updateCALayer(
                layer,
                context: .init(
                    coordinator: coordinator.coordinator,
                    environment: environment
                )
            )
        }
        .onDisappear {
            Representable.dismantleCALayer(
                coordinator: coordinator.coordinator
            )
        }
    }

    final class CoordinatorStorage: ObservableObject {
        var coordinator: Representable.Coordinator

        init(coordinator: Representable.Coordinator) {
            self.coordinator = coordinator
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
struct GradientLayer: CALayerRepresentable {
    func updateCALayer(_ layer: CAGradientLayer, context: Context) {
        #if os(iOS) || os(tvOS)
        layer.colors = [UIColor.green.cgColor, UIColor.blue.cgColor]
        #else
        layer.colors = [NSColor.green.cgColor, NSColor.blue.cgColor]
        #endif
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
struct LayerView_Previews: PreviewProvider {
    static var previews: some View {
        GradientLayer()
    }
}

#endif
