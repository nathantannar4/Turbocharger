//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

#if os(iOS)

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct CollectionViewIdealSizeLayout<
    Layout: CollectionViewLayout
>: CollectionViewLayout {

    public typealias UICollectionViewCellType = Layout.UICollectionViewCellType
    public typealias UICollectionViewSupplementaryViewType = Layout.UICollectionViewSupplementaryViewType

    public var layout: Layout
    public var preferredSize: CGSize?
    public var isScrollEnabled: Bool

    public init(
        layout: Layout,
        preferredSize: CGSize?,
        isScrollEnabled: Bool = true
    ) {
        self.layout = layout
        self.preferredSize = preferredSize
        self.isScrollEnabled = isScrollEnabled
    }

    public func makeUICollectionViewLayout(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> Layout.UICollectionViewLayoutType {
        layout.makeUICollectionViewLayout(context: context, options: options)
    }

    public func makeUICollectionView(
        context: Context,
        options: CollectionViewLayoutOptions
    ) -> UICollectionViewType {

        let layout = makeUICollectionViewLayout(context: context, options: options)
        let uiCollectionView = UICollectionViewType(
            frame: .zero,
            collectionViewLayout: layout
        )
        uiCollectionView.clipsToBounds = false
        uiCollectionView.keyboardDismissMode = .interactive
        uiCollectionView.backgroundColor = nil
        return uiCollectionView
    }

    public func updateUICollectionView(
        _ collectionView: UICollectionViewType,
        context: Context
    ) {
        collectionView.isScrollEnabled = isScrollEnabled
    }

    public func overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: ProposedSize,
        collectionView: UICollectionViewType
    ) {
        let contentSize = collectionView.contentSize
        let preferredSize = proposedSize.replacingUnspecifiedDimensions(
            by: preferredSize ?? CGSize(width: 10, height: 10)
        )
        print(#function, size, contentSize, proposedSize)
        if contentSize.height > 0 {
            if contentSize.height != preferredSize.height {
                let needsInset = contentSize.height < proposedSize.height ?? .infinity
                size.height = min(proposedSize.height ?? .infinity, contentSize.height + (needsInset ? 1 / 3 : 0))
            } else {
                size.height = preferredSize.height
            }
        } else if proposedSize.height == nil  {
            size.height = preferredSize.height
        }
        if contentSize.width > 0 {
            if contentSize.width != preferredSize.width {
                let needsInset = contentSize.width < proposedSize.width ?? .infinity
                size.width = min(proposedSize.width ?? .infinity, contentSize.width + (needsInset ? 1 / 3 : 0))
            } else {
                size.width = preferredSize.width
            }
        } else if proposedSize.width == nil {
            size.width = preferredSize.width
        }
    }

    open class UICollectionViewType: UICollectionView {
        open override var contentSize: CGSize {
            didSet {
                guard oldValue != contentSize else { return }
                invalidateIntrinsicContentSize()
            }
        }

        open override var intrinsicContentSize: CGSize {
            return contentSize
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CollectionViewLayout {

    public static func ideal<
        Layout: CollectionViewLayout
    >(
        layout: Layout,
        preferredSize: CGSize? = nil,
        isScrollEnabled: Bool = true
    ) -> CollectionViewIdealSizeLayout<Layout> where Self ==  CollectionViewIdealSizeLayout<Layout> {
        CollectionViewIdealSizeLayout(
            layout: layout,
            preferredSize: preferredSize,
            isScrollEnabled: isScrollEnabled
        )
    }
}

#endif

// MARK: - Previews

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CollectionViewIdealSizeLayout_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            StateAdapter(initialValue: 5) { $rows in
                VStack {
                    ScrollView {
                        CollectionViewVariadicView(
                            layout: .ideal(
                                layout: .compositional(axis: .horizontal),
                                preferredSize: CGSize(width: 10, height: 100)
                            )
                        ) {
                            ForEach(0..<rows, id: \.self) { value in
                                Text(value, format: .number)
                                    .frame(width: 30)
                            }
                        }
                        .border(Color.red)

                        CollectionViewVariadicView(
                            layout: .ideal(
                                layout: .compositional,
                                isScrollEnabled: false
                            )
                        ) {
                            ForEach(0..<rows, id: \.self) { value in
                                Text(value, format: .number)
                                    .frame(height: 30)
                            }
                        }
                        .border(Color.red)
                    }
                    .border(Color.yellow)
                    .padding()

                    CollectionViewVariadicView(
                        layout: .ideal(
                            layout: .compositional,
                            isScrollEnabled: false
                        )
                    ) {
                        ForEach(0..<rows, id: \.self) { value in
                            Text(value, format: .number)
                                .frame(height: 30)
                        }
                    }
                    .border(Color.red)

                    HStack {
                        Button {
                            withAnimation {
                                rows -= 1
                            }
                        } label: {
                            Text("Remove Row")
                        }

                        Button {
                            withAnimation {
                                rows += 1
                            }
                        } label: {
                            Text("Add Row")
                        }
                    }
                }
            }
        }
    }
}

#endif
