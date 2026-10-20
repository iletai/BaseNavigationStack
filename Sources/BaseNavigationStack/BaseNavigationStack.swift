// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation
import Observation

@MainActor
@Observable
/// Base Navigation Stack With Generic Type.
public final class BaseNavigationStack<ScreenView>: @unchecked Sendable where ScreenView: BaseViewProtocol {
    private(set) var state: RootingState
    public var urlHandler: (@MainActor (URL) -> OpenURLAction.Result)?

    public init(isPresented: Binding<ScreenView?> = .constant(nil)) {
        state = RootingState(
            isPresented: isPresented
        )
    }
}

public extension BaseNavigationStack {
    /// According navigation full screen flow of Apple
    /// https://developer.apple.com/design/human-interface-guidelines/going-full-screen
    /// Navigation Stack Push To View
    /// - Parameter viewSpec: Push View
    @MainActor
    func pushToView(_ viewSpec: ScreenView) {
        // Debounce: prevent duplicate immediate pushes of the exact same target
        if state.navigationPath.last != viewSpec {
            state.navigationPath.append(viewSpec)
        }
    }

    /// Pop To Back Previous View In Navigation Stack
    @MainActor
    func popBack() {
        state.navigationPath.removeLastSafe()
    }

    /// Pop To Root View Init In Navigation Stack
    @MainActor
    func navigateToRoot() {
        state.presentingFullScreen = nil
        state.presentingSheet = nil
        state.navigationPath.removeAll()
    }

    /// Change Base Navigation Stack
    /// - Parameter path: Replace With Another Navigation Path
    @MainActor
    func replaceNavigationStack(path: [ScreenView]) {
        state.presentingFullScreen = nil
        state.presentingSheet = nil
        state.navigationPath = path
    }

    /// Present Sheet With Define Type View
    /// - Parameter viewSpec: present Sheet View
    @MainActor
    func presentSheet(_ viewSpec: ScreenView) {
        state.presentingSheet = viewSpec
    }

    /// Full Screen View In Base Navigation Stack
    /// - Parameter viewSpec: PushViewTarget
    @MainActor
    func presentFullScreen(_ viewSpec: ScreenView) {
        state.presentingFullScreen = viewSpec
    }

    /// Dismiss If View Is Presenting or Embed In Navigation Stack
    @MainActor
    func dismiss() {
        if state.presentingSheet != nil {
            state.presentingSheet = nil
        } else if state.presentingFullScreen != nil {
            state.presentingFullScreen = nil
        } else if !state.navigationPath.isEmpty {
            state.navigationPath.removeLast()
        } else {
            state.isPresented.wrappedValue = nil
        }
    }

    @MainActor
    func handleOpenURL(url: URL) -> OpenURLAction.Result {
        return urlHandler?(url) ?? .systemAction
    }
}

public extension BaseNavigationStack {
    var navigationPath: Binding<[ScreenView]> {
        binding(keyPath: \.navigationPath)
    }

    var presentingSheet: Binding<ScreenView?> {
        binding(keyPath: \.presentingSheet)
    }

    var presentingFullScreen: Binding<ScreenView?> {
        binding(keyPath: \.presentingFullScreen)
    }

    var isPresented: Binding<ScreenView?> {
        state.isPresented
    }
}

extension BaseNavigationStack {
    /// Extension To Modify Value In Binding Data
    /// - Parameter keyPath: Binding<D>
    /// - Returns: Binding Scope
    func binding<D>(keyPath: WritableKeyPath<RootingState, D>) -> Binding<D> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.state[keyPath: keyPath] = $0 }
        )
    }
}
