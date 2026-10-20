//
//  NavigationRouterModifier.swift
//  BaseNavigationStack
//
//  Created by Claude on 19/10/2026.
//

import SwiftUI

public extension View {
    /// Binds a `NavigationRouter` to the current view hierarchy for Stack, Sheet, and Cover handling.
    @MainActor
    @ViewBuilder
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
        @Bindable var bindableRouter = router
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        self
            .navigationDestination(for: Route.self) { route in
                destination(route)
            }
            .sheet(item: $bindableRouter.sheet) { sheetTarget in
                sheet(sheetTarget)
            }
            .fullScreenCover(item: $bindableRouter.cover) { coverTarget in
                cover(coverTarget)
            }
            .environment(router)
        #else
        self
            .navigationDestination(for: Route.self) { route in
                destination(route)
            }
            .sheet(item: $bindableRouter.sheet) { sheetTarget in
                sheet(sheetTarget)
            }
            .environment(router)
        #endif
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
