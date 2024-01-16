<img src="./Logo.png" width="128"> 

# Turbocharger

`Turbocharger` aims accelerate SwiftUI development by providing commonly desired views and view modifiers. Highlights include an `AdaptiveStack` to better support dynamic type and `WeightedVStack`/`WeightedHStack` for relational layouts.

> Built for performance and backwards compatibility using [Engine](https://github.com/nathantannar4/Engine)

## See Also

- [Ignition](https://github.com/nathantannar4/Ignition)
- [Transmission](https://github.com/nathantannar4/Transmission)

## Requirements

- Deployment target: iOS 13.0, macOS 10.15, tvOS 13.0, or watchOS 6.0
- Xcode 15+

## Installation

### Xcode Projects

Select `File` -> `Swift Packages` -> `Add Package Dependency` and enter `https://github.com/nathantannar4/Turbocharger`.

### Swift Package Manager Projects

You can add `Turbocharger` as a package dependency in your `Package.swift` file:

```swift
let package = Package(
    //...
    dependencies: [
        .package(url: "https://github.com/nathantannar4/Turbocharger"),
    ],
    targets: [
        .target(
            name: "YourPackageTarget",
            dependencies: [
                .product(name: "Turbocharger", package: "Turbocharger"),
            ],
            //...
        ),
        //...
    ],
    //...
)
```

### Xcode Cloud / Github Actions / Fastlane / CI

[Engine](https://github.com/nathantannar4/Engine) includes a Swift macro, which requires user validation to enable or the build will fail. When configuring your CI, pass the flag `-skipMacroValidation` to `xcodebuild` to fix this.

## Introduction to Turbocharger

`Turbocharger` was started with the two goals. 1) To expand the standard API that SwiftUI provides to what many would commonly desired or need; and 2) To demonstrate how to use [Engine](https://github.com/nathantannar4/Engine) to make reusable components that are backwards compatible.

### LabeledView

```swift
/// The ``ViewStyle`` for ``LabeledView``
public protocol LabeledViewStyle: ViewStyle where Configuration == LabeledViewStyleConfiguration {
    associatedtype Configuration = Configuration
}

/// The ``ViewStyledView.Configuration`` for ``LabeledView``
public struct LabeledViewStyleConfiguration {
    /// A type-erased label of a ``LabeledView``
    public struct Label: ViewAlias { }
    public var label: Label

    /// A type-erased content of a ``LabeledView``
    public struct Content: ViewAlias { }
    public var content: Content
}

/// A backwards compatible port of `LabeledContent`
public struct LabeledView<Label: View, Content: View>: View {

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    )
}
```

### HVStack/AdaptiveStack

```swift
/// A view that arranges its subviews in a vertical or horizontal line.
@frozen
public struct HVStack<Content: View>: View {

    public init(
        axis: Axis,
        alignment: Alignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    )
}
    
/// A view that arranges its subviews in a horizontal line when such a layout
/// would fit the available space. If there is not enough space, it arranges it's subviews
/// in a vertical line.
@frozen
public struct AdaptiveStack<Content: View>: View {

    public init(
        alignment: Alignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    )
}
```

### WeightedHStack/WeightedVStack

```swift
/// A view that arranges its subviews in a horizontal line a width
/// that is relative to its `LayoutWeightPriority`.
///
/// By default, all subviews will be arranged with equal width.
///
@frozen
public struct WeightedHStack<Content: View>: View {

    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    )
}

/// A view that arranges its subviews in a vertical line a height
/// that is relative to its `LayoutWeightPriority`.
///
/// By default, all subviews will be arranged with equal height.
///
@frozen
public struct WeightedVStack<Content: View>: View {

    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    )
}

extension View {
    @ViewBuilder
    public func layoutWeight(_ value: Double) -> some View
}

```

### FlowStack

```swift
/// A view that arranges its subviews along multiple horizontal lines.
@frozen
public struct FlowStack<Content: View>: View {

    public init(
        alignment: Alignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    )
}
```

### RadialStack

```swift
/// A view that arranges its subviews along a radial circumference.
@frozen
public struct RadialStack<Content: View>: View {

    public init(radius: CGFloat? = nil, @ViewBuilder content: () -> Content)
}
```

### OptionalAdapter

```swift
/// A view maps an `Optional` value to it's `Content` or `Placeholder`.
@frozen
public struct OptionalAdapter<
    T,
    Content: View,
    Placeholder: View
>: View {

    @inlinable
    public init(
        _ value: T?,
        @ViewBuilder content: (T) -> Content,
        @ViewBuilder placeholder: () -> Placeholder
    )
    
    @inlinable
    public init(
        _ value: Binding<T?>,
        @ViewBuilder content: (Binding<T>) -> Content,
        @ViewBuilder placeholder: () -> Placeholder
    )
}

extension OptionalAdapter where Placeholder == EmptyView {
    @inlinable
    public init(
        _ value: T?,
        @ViewBuilder content: (T) -> Content
    )
    
    @inlinable
    public init(
        _ value: Binding<T?>,
        @ViewBuilder content: (Binding<T>) -> Content
    )
}
```

### ResultAdapter

```swift
/// A view maps a `Result` value to it's `SuccessContent` or `FailureContent`.
@frozen
public struct ResultAdapter<
    SuccessContent: View,
    FailureContent: View
>: View {

    @inlinable
    public init<Success, Failure: Error>(
        _ value: Result<Success, Failure>,
        @ViewBuilder content: (Success) -> SuccessContent,
        @ViewBuilder placeholder: (Failure) -> FailureContent
    )
    
    @inlinable
    public init<Success, Failure: Error>(
        _ value: Binding<Result<Success, Failure>>,
        @ViewBuilder content: (Binding<Success>) -> SuccessContent,
        @ViewBuilder placeholder: (Binding<Failure>) -> FailureContent
    )
}

extension ResultAdapter where FailureContent == EmptyView {
    @inlinable
    public init<Success, Failure: Error>(
        _ value: Result<Success, Failure>,
        @ViewBuilder content: (Success) -> SuccessContent
    )
    
    @inlinable
    public init<Success, Failure: Error>(
        _ value: Binding<Result<Success, Failure>>,
        @ViewBuilder content: (Binding<Success>) -> SuccessContent
    )
}
```

### BindingTransform

```swift
public protocol BindingTransform {
    associatedtype Input
    associatedtype Output

    func get(_ value: Input) -> Output
    func set(_ newValue: Output, oldValue: @autoclosure () -> Input) throws -> Input
}

extension Binding {
@inlinable
    public func projecting<Transform: BindingTransform>(
        _ transform: Transform
    ) -> Binding<Transform.Output> where Transform.Input == Value

    @inlinable
    public func isNil<Wrapped>() -> Binding<Bool> where Optional<Wrapped> == Value
    
    @inlinable
    public func isNotNil<Wrapped>() -> Binding<Bool> where Optional<Wrapped> == Value
    
    @inlinable
    public func map<T>(_ keyPath: WritableKeyPath<Value, T>) -> Binding<T>
}
```

### SafeAreaPadding

```swift
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension View {
    @inlinable
    public func safeAreaPadding(_ edgeInsets: EdgeInsets) -> some View

    @inlinable
    public func safeAreaPadding(_ length: CGFloat = 16) -> some View

    @inlinable
    public func safeAreaPadding(_ edges: Edge.Set, _ length: CGFloat = 16) -> some View
}
```

### Badge

```swift
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension View {
    @inlinable
    public func badge<Label: View>(
        alignment: Alignment = .topTrailing,
        anchor: UnitPoint = UnitPoint(x: 0.25, y: 0.25),
        scale:  CGFloat = 1.2,
        @ViewBuilder label: () -> Label
    ) -> some View
}
```

### Accessibility

```swift
extension View {
    /// Disables accessibility elements from being generated, even when an assistive technology is running
    @inlinable
    public func accessibilityDisabled() -> some View

    /// Optionally uses the specified string to identify the view.
    @inlinable
    public func accessibilityIdentifier(_ identifier: String?) -> ModifiedContent<Self, AccessibilityAttachmentModifier>

    /// Optionally adds a label to the view that describes its contents.
    @_disfavoredOverload
    @inlinable
    public func accessibilityLabel<S: StringProtocol>(_ label: S?) -> ModifiedContent<Self, AccessibilityAttachmentModifier>

    /// Optionally adds a textual description of the value that the view contains.
    @_disfavoredOverload
    @inlinable
    public func accessibilityValue<S: StringProtocol>(_ value: S?) -> ModifiedContent<Self, AccessibilityAttachmentModifier>
    
    /// Optionally adds an accessibility action to the view.
    @inlinable
    public func accessibilityAction(named name: LocalizedStringKey?, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier>

    /// Optionally adds an accessibility action to the view.
    @_disfavoredOverload
    @inlinable
    public func accessibilityAction<S: StringProtocol>(named name: S?, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier>
```

### And Many More

See the source files for more.

## License

Distributed under the BSD 2-Clause License. See ``LICENSE.md`` for more information.
