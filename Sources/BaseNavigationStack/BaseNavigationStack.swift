// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation
import Observation

@Observable
public class BaseNavigationStack<T, F> where T: Hashable, F: Hashable {
    public struct RootingState {
        var navigationPath = [T]()
        var presentingSheet: F? = nil
        var presentingFullScreen: T? = nil
        var presentingModal: T? = nil
        var isPresented: Binding<T?>
        
        var isPresenting: Bool {
            return presentingSheet != nil || presentingFullScreen != nil || presentingModal != nil
        }
    }
    
    private(set) var state: RootingState
    public var urlHandler: ((URL) -> OpenURLAction.Result)?
    
    public init(isPresented: Binding<T?>) {
        state = RootingState(isPresented: isPresented)
    }
}

public extension BaseNavigationStack {
    func pushToView(_ viewSpec: T) {
        state.navigationPath.append(viewSpec)
    }
    
    func popBack() {
        guard state.navigationPath.count > 1 else { return }
        state.navigationPath.removeLast()
    }
    
    func navigateToRoot() {
        if state.isPresenting {
            state.presentingFullScreen = nil
            state.presentingModal = nil
            state.presentingSheet = nil
        }
        state.navigationPath.removeAll()
    }
    
    func replaceNavigationStack(path: [T]) {
        state.navigationPath = path
    }
    
    func presentSheet(_ viewSpec: F) {
        state.presentingSheet = viewSpec
    }
    
    func presentFullScreen(_ viewSpec: T) {
        state.presentingFullScreen = viewSpec
    }
    
    func presentModal(_ viewSpec: T) {
        state.presentingModal = viewSpec
    }
    
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
    var navigationPath: Binding<[T]> {
        binding(keyPath: \.navigationPath)
    }
    
    var presentingSheet: Binding<F?> {
        binding(keyPath: \.presentingSheet)
    }
    
    var presentingFullScreen: Binding<T?> {
        binding(keyPath: \.presentingFullScreen)
    }
    
    var presentingModal: Binding<T?> {
        binding(keyPath: \.presentingModal)
    }
    
    var isPresented: Binding<T?> {
        state.isPresented
    }
}

extension BaseNavigationStack {
    func binding<D>(keyPath: WritableKeyPath<RootingState, D>) -> Binding<D> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.state[keyPath: keyPath] = $0 }
        )
    }
}
