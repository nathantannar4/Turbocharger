//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

#if !os(watchOS)

/// A protocol for defining a `NSViewRepresentable`/`UIViewRepresentable`
/// that has a  backwards compatible `sizeThatFits`
@MainActor @preconcurrency
public protocol PlatformViewRepresentable: DynamicProperty, PrimitiveView {

    #if os(macOS)
    associatedtype PlatformView: NSView
    #else
    associatedtype PlatformView: UIView
    #endif

    @MainActor @preconcurrency func makeView(context: Context) -> PlatformView
    @MainActor @preconcurrency func updateView(_ view: PlatformView, context: Context)
    @MainActor @preconcurrency func sizeThatFits(_ proposal: ProposedSize, view: PlatformView) -> CGSize?
    @MainActor @preconcurrency static func dismantleView(_ view: PlatformView, coordinator: Coordinator)

    associatedtype Coordinator = Void
    @MainActor @preconcurrency func makeCoordinator() -> Coordinator

    typealias Context = _PlatformViewRepresentableBody<Self>.Context
}

extension PlatformViewRepresentable {
    func sizeThatFits(_ proposal: ProposedSize, view: PlatformView) -> CGSize? { nil }
    static func dismantleView(_ view: PlatformView, coordinator: Coordinator) { }
}

extension PlatformViewRepresentable where Coordinator == Void {
    func makeCoordinator() -> Coordinator { () }
}

extension PlatformViewRepresentable {

    private var content: _PlatformViewRepresentableBody<Self> {
        _PlatformViewRepresentableBody(representable: self)
    }

    public static func makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs {
        _PlatformViewRepresentableBody<Self>._makeView(view: view[\.content], inputs: inputs)
    }

    public static func makeViewList(
        view: _GraphValue<Self>,
        inputs: _ViewListInputs
    ) -> _ViewListOutputs {
        _PlatformViewRepresentableBody<Self>._makeViewList(view: view[\.content], inputs: inputs)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
    public static func viewListCount(
        inputs: _ViewListCountInputs
    ) -> Int? {
        _PlatformViewRepresentableBody<Self>._viewListCount(inputs: inputs)
    }
}

#if os(macOS)
public struct _PlatformViewRepresentableBody<
    Representable: PlatformViewRepresentable
>: NSViewRepresentable {

    var representable: Representable

    public func makeNSView(
        context: Context
    ) -> Representable.PlatformView {
        representable.makeView(context: context)
    }

    public func updateNSView(
        _ nsView: Representable.PlatformView,
        context: Context
    ) {
        representable.updateView(nsView, context: context)
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, *)
    public func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView: Representable.PlatformView,
        context: Context
    ) -> CGSize? {
        representable.sizeThatFits(ProposedSize(proposal), view: nsView)
    }

    public func _overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: _ProposedSize,
        nsView: Representable.PlatformView
    ) {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, *) {
            // Already handled
        } else if let sizeThatFits = representable.sizeThatFits(ProposedSize(proposedSize), view: nsView) {
            size = sizeThatFits
        }
    }

    public static func dismantleNSView(
        _ nsView: Representable.PlatformView,
        coordinator: Coordinator
    ) {
        Representable.dismantleView(nsView, coordinator: coordinator)
    }

    public func makeCoordinator() -> Representable.Coordinator {
        representable.makeCoordinator()
    }
}
#else
public struct _PlatformViewRepresentableBody<
    Representable: PlatformViewRepresentable
>: UIViewRepresentable {

    var representable: Representable

    public func makeUIView(
        context: Context
    ) -> Representable.PlatformView {
        representable.makeView(context: context)
    }

    public func updateUIView(
        _ uiView: Representable.PlatformView,
        context: Context
    ) {
        representable.updateView(uiView, context: context)
    }

    @available(iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: Representable.PlatformView,
        context: Context
    ) -> CGSize? {
        representable.sizeThatFits(ProposedSize(proposal), view: uiView)
    }

    public func _overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: _ProposedSize,
        uiView: Representable.PlatformView
    ) {
        if #available(iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            // Already handled
        } else if let sizeThatFits = representable.sizeThatFits(ProposedSize(proposedSize), view: uiView) {
            size = sizeThatFits
        }
    }

    public static func dismantleUIView(
        _ uiView: Representable.PlatformView,
        coordinator: Coordinator
    ) {
        Representable.dismantleView(uiView, coordinator: coordinator)
    }

    public func makeCoordinator() -> Representable.Coordinator {
        representable.makeCoordinator()
    }
}
#endif

#endif // !os(watchOS)
