//
// Copyright (c) Nathan Tannar
//

import Engine
import SwiftUI

public struct AsyncForEach<
    Section: Hashable,
    Data: RandomAccessCollection,
    Content: View,
    ID: Hashable
>: View where Data.Element: Identifiable {

    nonisolated(unsafe) var values: [AsyncValue<Section, Data.Element>]
    var keyPath: KeyPath<AsyncValue<Section, Data.Element>, ID>
    var content: (AsyncValue<Section, Data.Element>) -> Content

    public init(
        _ data: Optional<Data>,
        keyPath: KeyPath<AsyncValue<Section, Data.Element>, ID>,
        section: Section? = nil,
        placeholders: Int,
        @ViewBuilder content: @escaping (AsyncValue<Section, Data.Element>) -> Content
    ) {
        var values = data?.enumerated().compactMap {
            AsyncValue(value: $0.element, offset: .init(index: $0.offset, section: section))
        } ?? []
        let placeholders = (0..<Swift.max(0, placeholders)).map {
            AsyncValue<Section, Data.Element>(offset: .init(index: $0 + values.count, section: section))
        }
        values.append(contentsOf: placeholders)
        self.values = values
        self.keyPath = keyPath
        self.content = content
    }

    public var body: some View {
        ForEach(values, id: keyPath) { value in
            content(value)
        }
    }
}

extension AsyncForEach {
    public init(
        _ data: Optional<Data>,
        placeholders: Int,
        @ViewBuilder content: @escaping (Data.Element?) -> Content
    ) where ID == AnyHashable, Section == ID {
        self.init(data, keyPath: \.id, placeholders: placeholders) { value in
            content(value.value)
        }
    }

    public init(
        _ data: Optional<Data>,
        keyPath: KeyPath<AsyncValue<Section, Data.Element>, ID>,
        placeholders: Int,
        @ViewBuilder content: @escaping (AsyncValue<Section, Data.Element>) -> Content
    ) where Section == Data.Element.ID {
        self.init(
            data,
            keyPath: keyPath,
            section: nil,
            placeholders: placeholders,
            content: content
        )
    }

    public init<
        _Data: RandomAccessCollection,
        _ID: Hashable
    >(
        _ data: Optional<_Data>,
        id: KeyPath<_Data.Element, _ID>,
        keyPath: KeyPath<AsyncValue<Section, Data.Element>, ID>,
        section: Section? = nil,
        placeholders: Int,
        @ViewBuilder content: @escaping (AsyncValue<Section, Data.Element>) -> Content
    ) where Data == Array<IdentifiableBox<_Data.Element, _ID>> {
        let data = data?.compactMap {
            IdentifiableBox($0, id: id)
        }
        self.init(data, keyPath: keyPath, section: section, placeholders: placeholders) { value in
            content(value)
        }
    }

    public init<
        _Data: RandomAccessCollection
    >(
        _ data: Optional<_Data>,
        id: KeyPath<_Data.Element, Section>,
        keyPath: KeyPath<AsyncValue<Section, Data.Element>, ID>,
        placeholders: Int,
        @ViewBuilder content: @escaping (AsyncValue<Section, Data.Element>) -> Content
    ) where Data == Array<IdentifiableBox<_Data.Element, Section>> {
        self.init(
            data,
            id: id,
            keyPath: keyPath,
            section: nil,
            placeholders: placeholders,
            content: content
        )
    }

    public init<
        _Data: RandomAccessCollection
    >(
        _ data: Optional<_Data>,
        id: KeyPath<_Data.Element, Section>,
        placeholders: Int,
        @ViewBuilder content: @escaping (Data.Element?) -> Content
    ) where Data == Array<IdentifiableBox<_Data.Element, Section>>, ID == AnyHashable {
        self.init(data, id: id, keyPath: \.id, placeholders: placeholders) { value in
            content(value.value)
        }
    }
}

extension AsyncForEach: DynamicViewContent {
    public nonisolated var data: [Data.Element] {
        values.compactMap { $0.value }
    }
}

@frozen
public struct AsyncValue<Section: Hashable, Value: Identifiable>: Identifiable {

    public struct Offset: Hashable {
        public var index: Int
        public var section: Section?
    }

    public var value: Value?
    public var offset: Offset

    public var id: AnyHashable {
        if let value {
            return value.id
        }
        return offset
    }
}

extension AsyncValue: Equatable where Value: Equatable { }
extension AsyncValue: Hashable where Value: Hashable { }

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
struct AsyncForEach_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview1()
        }
        Preview2()
    }

    struct Preview1: View {
        @State var numbers: [Int] = []
        @State var isLoading = true

        var body: some View {
            ScrollView {
                HStack(alignment: .top, spacing: 0) {
                    VStack {
                        ForEach(
                            numbers,
                            id: \.self
                        ) { number in
                            CellView(number: number)
                        }

                        if isLoading {
                            CellView(number: nil)
                            CellView(number: nil)
                            CellView(number: nil)
                        }
                    }

                    VStack {
                        AsyncForEach(
                            numbers,
                            id: \.self,
                            keyPath: \.id,
                            placeholders: isLoading ? 3 : 0
                        ) { number in
                            CellView(number: number.value?.value)
                        }
                    }

                    VStack {
                        AsyncForEach(
                            numbers,
                            id: \.self,
                            keyPath: \.offset,
                            placeholders: isLoading ? 3 : 0
                        ) { number in
                            CellView(number: number.value?.value)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
            }
            .animation(.default, value: numbers)
            .overlay(
                HStack {
                    Button {
                        withAnimation {
                            numbers.shuffle()
                        }
                    } label: {
                        Text("Shuffle")
                    }

                    Button {
                        isLoading.toggle()
                    } label: {
                        Text("Toggle Loading")
                    }

                    Button {
                        withAnimation {
                            numbers += [numbers.count, numbers.count + 1, numbers.count + 2]
                        }
                    } label: {
                        Text("Add")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            )
        }

        struct CellView: View {
            var number: Int?

            var body: some View {
                HStack {
                    Circle()
                        .fill(Color.primary.opacity(0.16))
                        .frame(width: 32, height: 32)

                    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                        Text(number?.description ?? String(repeating: "*", count: 8))
                            .contentTransition(.numericText())
                    } else {
                        Text(number?.description ?? String(repeating: "*", count: 8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .shimmer(isActive: number == nil)

            }
        }
    }

    struct Preview2: View {
        var body: some View {
            ScrollView {
                LazyVStack {
                    AsyncForEach(
                        [1, 2, 3],
                        id: \.self,
                        keyPath: \.offset,
                        placeholders: 3
                    ) { element in
                        Section {
                            AsyncForEach(
                                ["One", "Two", "Three"],
                                id: \.self,
                                keyPath: \.offset,
                                section: element.offset,
                                placeholders: 3
                            ) { element in
                                Text(element.value?.value ?? "***")
                            }
                        } header: {
                            Text("Header")
                        }
                    }
                }
            }
        }
    }
}
