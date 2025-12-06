//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Combine

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
open class CollectionViewDataPrefetcher<
    Item: Equatable & Identifiable
>: ObservableObject where Item.ID: Equatable & Sendable {

    open func startPrefetching(items: [Item]) {

    }

    open func cancelPrefetching(items: [Item]) {

    }

    open func cancelPrefetching() {

    }
}

// MARK: - Previews

#if os(iOS)

@available(iOS 14.0, *)
struct CollectionViewDataPrefetcher_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {

        struct Item: Identifiable, Equatable {
            let id = UUID()
            var value: Int?
        }

        @State var data: [Item] = (0..<30).map { Item(value: $0) }

        class Prefetcher: CollectionViewDataPrefetcher<Item> {
            override func startPrefetching(items: [Item]) {
                print("Prefetch \(items)")
            }
        }

        var body: some View {
            CollectionView(
                .compositional,
                items: data
            ) { indexPath, section, item in
                HStack {
                    Circle()
                        .frame(width: 32, height: 32)

                    Text(item.value?.description ?? "Placeholder")
                }
                .padding()
                .shimmer(isActive: item.value == nil)
            }
            .onItemWillAppear { _, section, item in
                guard item.value != nil, item.id == section.items.last?.id else { return }
                Task { @MainActor in
                    print("onItemWillAppear")
                    data.append(
                        contentsOf: (0..<3).map { _ in Item(value: nil) }
                    )
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    var data = data
                    data.removeAll(where: { $0.value == nil })
                    data.append(
                        contentsOf: (data.count..<(data.count + 10)).map { Item(value: $0) }
                    )
                    withAnimation {
                        self.data = data
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}

#endif
