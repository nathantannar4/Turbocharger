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
    public var isScrollEnabled: Bool

    public init(
        layout: Layout,
        isScrollEnabled: Bool = false
    ) {
        self.layout = layout
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
        if contentSize.height > 0 {
            let needsInset = contentSize.height < proposedSize.height ?? .infinity
            size.height = min(proposedSize.height ?? .infinity, contentSize.height + (needsInset ? 1 / 3 : 0))
        } else if proposedSize.height == nil  {
            size.height = 10_000
        }
        if contentSize.width > 0 {
            let needsInset = contentSize.width < proposedSize.width ?? .infinity
            size.width = min(proposedSize.width ?? .infinity, contentSize.width + (needsInset ? 1 / 3 : 0))
        } else if proposedSize.width == nil {
            size.width = 10_000
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
                            layout: CollectionViewIdealSizeLayout(
                                layout: .compositional
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
                        layout: CollectionViewIdealSizeLayout(
                            layout: .compositional
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
