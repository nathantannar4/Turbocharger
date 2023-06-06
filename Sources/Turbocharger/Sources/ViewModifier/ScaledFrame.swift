//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ScaledFrameModifier: ViewModifier {
    var width: CGFloat?
    var height: CGFloat?
    var alignment: Alignment
    @ScaledMetric var scale: CGFloat

    public init(
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        alignment: Alignment,
        relativeTo textSyle: Font.TextStyle
    ) {
        self.width = width
        self.height = height
        self.alignment = alignment
        self._scale = ScaledMetric(wrappedValue: 1, relativeTo: textSyle)
    }

    public func body(content: Content) -> some View {
        content.frame(
            width: width?.scaled(by: scale),
            height: height?.scaled(by: scale),
            alignment: alignment
        )
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct ScaledBoundsModifier: ViewModifier {
    var minWidth: CGFloat?
    var maxWidth: CGFloat?
    var minHeight: CGFloat?
    var maxHeight: CGFloat?
    var alignment: Alignment
    @ScaledMetric var scale: CGFloat

    public init(
        minWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        alignment: Alignment,
        relativeTo textSyle: Font.TextStyle
    ) {
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.alignment = alignment
        self._scale = ScaledMetric(wrappedValue: 1, relativeTo: textSyle)
    }

    public func body(content: Content) -> some View {
        content.frame(
            minWidth: minWidth?.scaled(by: scale),
            maxWidth: maxWidth?.scaled(by: scale),
            minHeight: minHeight?.scaled(by: scale),
            maxHeight: maxHeight?.scaled(by: scale),
            alignment: alignment
        )
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension View {
    public func frame(_ size: CGFloat?, relativeTo textSyle: Font.TextStyle) -> some View {
        frame(width: size, height: size, alignment: .center, relativeTo: textSyle)
    }

    public func frame(
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        alignment: Alignment = .center,
        relativeTo textSyle: Font.TextStyle
    ) -> some View {
        modifier(ScaledFrameModifier(width: height, height: width, alignment: alignment, relativeTo: textSyle))
    }

    public func frame(
        minWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        alignment: Alignment = .center,
        relativeTo textSyle: Font.TextStyle
    ) -> some View {
        modifier(ScaledBoundsModifier(minWidth: minWidth, maxWidth: maxWidth, minHeight: minHeight, maxHeight: maxHeight, alignment: alignment, relativeTo: textSyle))
    }
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ScaledFrame_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Circle()
                .fill(Color.yellow)
                .frame(width: 40, height: 40, relativeTo: .body)

            Circle()
                .fill(Color.yellow)
                .frame(width: 40, height: 40, relativeTo: .body)
                .dynamicTypeSize(.accessibility1)
        }
    }
}
