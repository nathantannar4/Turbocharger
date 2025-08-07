//
// Copyright (c) Nathan Tannar
//

import SwiftUI

public struct AsyncForEach<
    Data: RandomAccessCollection,
    Content: View
>: View where Data.Element: Identifiable {

    nonisolated(unsafe) var values: [AsyncValue<Data.Element>]
    var content: (Optional<Data.Element>) -> Content

    public init(
        _ data: Optional<Data>,
        placeholders: Int,
        @ViewBuilder content: @escaping (Optional<Data.Element>) -> Content
    ) {
        var values = data?.compactMap {
            AsyncValue.value($0)
        } ?? []
        let placeholders = (0..<Swift.max(0, placeholders)).map {
            AsyncValue<Data.Element>.placeholder(.init(index: $0))
        }
        values.append(contentsOf: placeholders)
        self.values = values
        self.content = content
    }

    public var body: some View {
        ForEach(values) { value in
            content(value.asOptional())
        }
    }
}

extension AsyncForEach {
    public init<
        _Data: RandomAccessCollection,
        ID: Hashable
    >(
        _ data: Optional<_Data>,
        id: KeyPath<_Data.Element, ID>,
        placeholders: Int,
        @ViewBuilder content: @escaping (Optional<_Data.Element>) -> Content
    ) where Data == Array<IdentifiableBox<_Data.Element, ID>> {
        let data = data?.compactMap {
            IdentifiableBox($0, id: id)
        }
        self.init(data, placeholders: placeholders) { box in
            content(box?.value)
        }
    }
}

extension AsyncForEach: DynamicViewContent {
    public nonisolated var data: [Data.Element] {
        values.compactMap { $0.asOptional() }
    }
}

enum AsyncValue<Value: Identifiable>: Identifiable {
    case value(Value)
    struct Placeholder: Hashable, Sendable {
        var index: Int
    }
    case placeholder(Placeholder)

    var id: AnyHashable {
        switch self {
        case .value(let value):
            return AnyHashable(value.id)
        case .placeholder(let placeholder):
            return AnyHashable(placeholder)
        }
    }

    func asOptional() -> Value? {
        switch self {
        case .value(let value):
            return value
        case .placeholder:
            return nil
        }
    }
}

extension AsyncValue: Equatable where Value: Equatable { }

extension AsyncValue: Hashable where Value: Hashable { }

extension AsyncValue: Sendable where Value: Sendable { }

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
struct AsyncForEach_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var numbers: [Int] = []
        @State var isLoading = true

        var body: some View {
            ScrollView {
                VStack {
                    AsyncForEach(numbers, id: \.self, placeholders: isLoading ? 3 : 0) { number in
                        HStack {
                            Circle()
                                .fill(Color.primary.opacity(0.16))
                                .frame(width: 32, height: 32)

                            Text(number?.description ?? String(repeating: "*", count: 12))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .shimmer(isActive: number == nil)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
            }
            .animation(.default, value: numbers)
            .overlay(
                HStack {
                    Button {
                        isLoading.toggle()
                    } label: {
                        Text("Toggle Loading")
                    }

                    Button {
                        numbers += [numbers.count, numbers.count + 1, numbers.count + 2]
                    } label: {
                        Text("Add")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            )
        }
    }
}
