//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

#if !os(watchOS)

/// A wrapper for a QuartzCore layer that you use to integrate that layer into your
/// SwiftUI view hierarchy.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@MainActor @preconcurrency
public protocol CALayerRepresentable: PrimitiveView {

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
extension CALayerRepresentable where Coordinator == Void {
    public func makeCoordinator() -> Coordinator { () }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
extension CALayerRepresentable {
    public static func dismantleCALayer(_ layer: CALayerType, coordinator: Coordinator) { }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
@frozen
public struct CALayerRepresentableContext<
    Representable: CALayerRepresentable
> {
    public var coordinator: Representable.Coordinator
    public var environment: EnvironmentValues
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
extension CALayerRepresentable {

    private nonisolated var content: CALayerRepresentableBody<Self> {
        CALayerRepresentableBody(representable: self)
    }

    public nonisolated static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        CALayerRepresentableBody<Self>._makeView(view: view[\.content], inputs: inputs)
    }

    public nonisolated static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        CALayerRepresentableBody<Self>._makeViewList(view: view[\.content], inputs: inputs)
    }

    public nonisolated static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        CALayerRepresentableBody<Self>._viewListCount(inputs: inputs)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
private struct CALayerRepresentableBody<
    Representable: CALayerRepresentable
>: View {
    nonisolated(unsafe) var representable: Representable

    var body: some View {
        CALayerRepresentableRenderer(
            representable: representable
        )
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
private struct CALayerRepresentableRenderer<
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
        .onDisappear {
            storage.dismantle()
        }
    }

    final class Storage: ObservableObject {
        var layer: Representable.CALayerType?
        var coordinator: Representable.Coordinator
        var transaction = Transaction()

        init(coordinator: Representable.Coordinator) {
            self.coordinator = coordinator
        }

        @MainActor
        func dismantle() {
            if let layer {
                Representable.dismantleCALayer(
                    layer,
                    coordinator: coordinator
                )
            }
            layer = nil
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
struct GradientLayer_Previews: PreviewProvider {

    struct GradientLayer: CALayerRepresentable {
        var colors: [Color]

        func makeCALayer(_ layer: CAGradientLayer, context: Context) { }

        func updateCALayer(_ layer: CAGradientLayer, context: Context) {
            let colors = colors.map { $0.toCGColor(in: context.environment) }

            let animation = CABasicAnimation(keyPath: "colors")
            animation.fromValue = layer.presentation()?.colors ?? layer.colors
            animation.toValue = colors
            animation.duration = 1
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = true

            layer.colors = colors
            layer.add(animation, forKey: "colors")
        }
    }

    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var colors = [Color.red, .orange, .yellow]

        var body: some View {
            VStack {
                HStack(spacing: 0) {
                    GradientLayer(colors: colors)

                    LinearGradient(
                        colors: colors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .animation(.linear(duration: 1), value: colors)
                }

                Button {
                    var colors = colors
                    colors.insert(colors.popLast()!, at: 0)
                    self.colors = colors
                } label: {
                    Text("Animate")
                }
            }
        }
    }
}

#endif
