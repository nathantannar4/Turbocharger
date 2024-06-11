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
@MainActor @preconcurrency
public protocol CALayerRepresentable: View where Body == Never {
    associatedtype CALayerType: CALayer

    /// Configures the layers initial state.
    ///
    /// Configure the view using your app's current data and contents of the
    /// `context` parameter. The system calls this method only once, when it
    /// creates your layer for the first time. For all subsequent updates, the
    /// system calls the ``CALayerRepresentable/updateCALayer(_:context:)``
    /// method.
    /// 
    @MainActor @preconcurrency func makeCALayer(_ layer: CALayerType, context: Context)

    /// Updates the layer with new information.
    ///
    /// > Note: This protocol implementation is optional
    ///
    @MainActor @preconcurrency func updateCALayer(_ layer: CALayerType, context: Context)

    associatedtype Coordinator = Void

    @MainActor @preconcurrency func makeCoordinator() -> Coordinator

    /// Cleans up the layer in anticipation of it's removal.
    @MainActor @preconcurrency static func dismantleCALayer(_ layer: CALayerType, coordinator: Coordinator)

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
    public static func dismantleCALayer(_ layer: CALayerType, coordinator: Coordinator) { }
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

    @StateObject var storage: Storage
    @Environment(\.self) var environment

    init(representable: Representable) {
        self.representable = representable
        self._storage = StateObject(
            wrappedValue: Storage(
                coordinator: representable.makeCoordinator()
            )
        )
    }

    var body: some View {
        _CALayerView(type: Representable.CALayerType.self) { layer in
            let context = CALayerRepresentableContext<Representable>(
                coordinator: storage.coordinator,
                environment: environment
            )
            if storage.layer == nil {
                storage.layer = layer
                representable.makeCALayer(
                    layer,
                    context: context
                )
            }
            representable.updateCALayer(
                layer,
                context: context
            )
        }
    }

    final class Storage: ObservableObject {
        var layer: Representable.CALayerType!
        var coordinator: Representable.Coordinator

        init(coordinator: Representable.Coordinator) {
            self.coordinator = coordinator
        }

        deinit {
            if let layer {
                Representable.dismantleCALayer(
                    layer,
                    coordinator: coordinator
                )
            }
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
struct GradientLayer: CALayerRepresentable {
    func makeCALayer(_ layer: CAGradientLayer, context: Context) {
        #if os(macOS)
        layer.colors = [NSColor.green.cgColor, NSColor.blue.cgColor]
        #else
        layer.colors = [UIColor.green.cgColor, UIColor.blue.cgColor]
        #endif
    }

    func updateCALayer(_ layer: CAGradientLayer, context: Context) {
        
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@available(watchOS, unavailable)
struct GradientLayer_Previews: PreviewProvider {
    static var previews: some View {
        GradientLayer()
    }
}

#endif
