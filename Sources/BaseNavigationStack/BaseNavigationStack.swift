// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation
import Observation

@Observable
/// Base Navigation Stack With Generic Type.
public class BaseNavigationStack<ScreenView> where ScreenView: Hashable {
    private(set) var state: RootingState
    public var urlHandler: ((URL) -> OpenURLAction.Result)?
    public init(isPresented: Binding<ScreenView?>) {
        state = RootingState(isPresented: isPresented)
    }
}

public extension BaseNavigationStack {
    /// According navigation full screen flow of Apple
    /// https://developer.apple.com/design/human-interface-guidelines/going-full-screen
    /// We Will Only Support Case Full Screen To Target Last View Embed In Navigation Stack
    /// So If View Is Presenting SomeView. Must Dismiss. If Want To Navigation To Another View But Also Keep Current.
    /// Please Embed Target View In Owner Navigation Stack Different
    /// Navigation Stack Push To View
    /// - Parameter viewSpec: Push View
    @MainActor
    func pushToView(_ viewSpec: ScreenView) {
        // if state.isPresenting { dismiss() }
        state.navigationPath.append(viewSpec)
    }
    
    /// Pop To Back Previous View In Navigation Stack
    @MainActor
    func popBack() {
        state.navigationPath.removeLastSafe()
    }
    
    /// Pop To Root View Init In Navigation Stack
    @MainActor
    func navigateToRoot() {
        if state.isPresenting {
            state.presentingFullScreen = nil
            state.presentingModal = nil
            state.presentingSheet = nil
        }
        state.navigationPath.removeAllSafe()
    }
    
    /// Change Base Navigation Stack
    /// - Parameter path: Replace With Another Navigation Path
    @MainActor
    func replaceNavigationStack(path: [ScreenView]) {
        state.navigationPath = path
    }

    /// Present Sheet With Define Type<F> View
    /// - Parameter viewSpec: present Sheet View
    @MainActor
    func presentSheet(_ viewSpec: ScreenView) {
        // if state.isPresenting { dismiss() }
        state.presentingSheet = viewSpec
    }

    /// Full Screen View In Bas Navigation Stack
    /// - Parameter viewSpec: PushViewTarget
    @MainActor
    func presentFullScreen(_ viewSpec: ScreenView) {
        // if state.isPresenting { dismiss() }
        state.presentingFullScreen = viewSpec
    }
    
    /// Present Modal View
    /// - Parameter viewSpec: PushViewTarget
    @MainActor
    func presentModal(_ viewSpec: ScreenView) {
        state.presentingModal = viewSpec
    }
    
    /// Dismiss If View Is Presenting or Embed In Navigation Stack
    @MainActor
    func dismiss() {
        if state.presentingSheet != nil {
            state.presentingSheet = nil
        } else if state.presentingFullScreen != nil {
            state.presentingFullScreen = nil
        } else if state.presentingModal != nil {
            state.presentingModal = nil
        } else if navigationPath.count > 1 {
            state.navigationPath.removeLast()
        } else {
            state.isPresented.wrappedValue = nil
        }
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
    
    var presentingModal: Binding<ScreenView?> {
        binding(keyPath: \.presentingModal)
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
