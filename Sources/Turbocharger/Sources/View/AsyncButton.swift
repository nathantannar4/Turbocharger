//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@frozen
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct AsyncButton<Label: View>: View {

    public var label: Label
    public var role: ButtonRole?
    public var animation: Animation?
    public var action: () async -> Void

    @StateOrBinding private var isLoading: Bool
    @State private var trigger: UInt = 0

    public init(
        role: ButtonRole? = nil,
        animation: Animation? = .default,
        action: @escaping () async -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.role = role
        self._isLoading = .init(false)
        self.animation = animation
        self.action = action
        self.label = label()
    }

    public init(
        role: ButtonRole? = nil,
        isLoading: Binding<Bool>,
        animation: Animation? = .default,
        action: @escaping () async -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.role = role
        self._isLoading = .init(isLoading)
        self.animation = animation
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(role: role) {
            trigger &+= 1
            withAnimation(animation) {
                isLoading = true
            }
        } label: {
            label
        }
        .disabled(isLoading)
        .task(id: trigger, priority: .userInitiated) {
            guard trigger > 0 else { return }
            await action()
            withAnimation(animation) {
                isLoading = false
            }
        }
    }
}

// MARK: - Previews

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct AsyncButton_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var isLoading = false

        var body: some View {
            VStack {
                AsyncButton {
                    print("started")
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    print("finished")
                } label: {
                    Text("Load")
                }

                AsyncButton(isLoading: $isLoading, animation: .spring) {
                    print("started")
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    print("finished")
                } label: {
                    Text("Load")
                        .overlay {
                            if isLoading {
                                ProgressView()
                            }
                        }
                }
            }
        }
    }
}
