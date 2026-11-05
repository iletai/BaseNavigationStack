//
//  NavigationRouterModifier.swift
//  BaseNavigationStack
//
//  Created by Claude on 19/10/2026.
//

import SwiftUI

public extension View {
    /// Attaches a `NavigationRouter`'s destinations, sheet, and cover to this view, and injects the router
    /// into the environment.
    ///
    /// Apply it to the root content *inside* a `NavigationStack(path: $router.path)`; this modifier does not
    /// bind `path` itself. Pushed destinations, sheets, and covers all receive the router through the
    /// environment. Use `BaseNavigationContainer` to get the stack and binding for free.
    @MainActor
    func navigationRouter<
        Route: Hashable & Sendable,
        Sheet: Identifiable & Hashable & Sendable,
        Cover: Identifiable & Hashable & Sendable,
        Destination: View,
        SheetContent: View,
        CoverContent: View
    >(
        _ router: NavigationRouter<Route, Sheet, Cover>,
        @ViewBuilder destination: @escaping (Route) -> Destination,
        @ViewBuilder sheet: @escaping (Sheet) -> SheetContent,
        @ViewBuilder cover: @escaping (Cover) -> CoverContent
    ) -> some View {
        modifier(RouterModifier(router: router, destination: destination, sheet: sheet, cover: cover))
    }

    /// Convenience modifier for Stack-only routing.
    @MainActor
    func navigationRouter<
        Route: Hashable & Sendable,
        Sheet: Identifiable & Hashable & Sendable,
        Cover: Identifiable & Hashable & Sendable,
        Destination: View
    >(
        _ router: NavigationRouter<Route, Sheet, Cover>,
        @ViewBuilder destination: @escaping (Route) -> Destination
    ) -> some View {
        navigationRouter(
            router,
            destination: destination,
            sheet: { _ in EmptyView() },
            cover: { _ in EmptyView() }
        )
    }
}

extension View {
    /// `fullScreenCover` where available; macOS has no full screen cover, so it falls back to a sheet.
    @ViewBuilder
    func coverPresentation<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(macOS)
        sheet(item: item, content: content)
        #else
        fullScreenCover(item: item, content: content)
        #endif
    }
}

private struct RouterModifier<
    Route: Hashable & Sendable,
    Sheet: Identifiable & Hashable & Sendable,
    Cover: Identifiable & Hashable & Sendable,
    Destination: View,
    SheetContent: View,
    CoverContent: View
>: ViewModifier {
    @Bindable var router: NavigationRouter<Route, Sheet, Cover>
    let destination: (Route) -> Destination
    let sheet: (Sheet) -> SheetContent
    let cover: (Cover) -> CoverContent
    @Namespace private var namespace

    func body(content: Content) -> some View {
        // Pushed destinations take their environment from the NavigationStack, not from this view,
        // so the router and zoom namespace are injected into each destination. Sheets and covers
        // inherit them from this view.
        content
            .navigationDestination(for: Route.self) { route in
                destination(route)
                    .environment(router)
                    .environment(\.navigationTransitionNamespace, namespace)
                    .modifier(ZoomDestinationModifier(sourceID: router.zoomSources[route]))
            }
            .sheet(item: $router.sheet) { target in
                sheet(target)
                    .modifier(SheetOptionsModifier(options: (target as? SheetPresentable)?.sheetOptions))
            }
            .coverPresentation(item: $router.cover) { target in
                cover(target)
            }
            .environment(router)
            .environment(\.navigationTransitionNamespace, namespace)
    }
}
