//
//  BaseNavigationContainer.swift
//  BaseNavigationStack
//
//  Created by Claude on 19/10/2026.
//

import SwiftUI

/// Declarative SwiftUI Container encapsulating NavigationStack, destinations, and modal presentations.
public struct BaseNavigationContainer<
    Route: Hashable & Sendable,
    Sheet: Identifiable & Hashable & Sendable,
    Cover: Identifiable & Hashable & Sendable,
    Content: View,
    Destination: View,
    SheetContent: View,
    CoverContent: View
>: View {
    @Bindable private var router: NavigationRouter<Route, Sheet, Cover>
    private let content: () -> Content
    private let destination: (Route) -> Destination
    private let sheetContent: (Sheet) -> SheetContent
    private let coverContent: (Cover) -> CoverContent

    public init(
        router: NavigationRouter<Route, Sheet, Cover>,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder destination: @escaping (Route) -> Destination,
        @ViewBuilder sheet: @escaping (Sheet) -> SheetContent,
        @ViewBuilder cover: @escaping (Cover) -> CoverContent
    ) {
        self.router = router
        self.content = content
        self.destination = destination
        self.sheetContent = sheet
        self.coverContent = cover
    }

    public var body: some View {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        NavigationStack(path: $router.path) {
            content()
                .navigationDestination(for: Route.self) { route in
                    destination(route)
                }
                .sheet(item: $router.sheet) { sheet in
                    sheetContent(sheet)
                }
                .fullScreenCover(item: $router.cover) { cover in
                    coverContent(cover)
                }
        }
        .environment(router)
        #else
        NavigationStack(path: $router.path) {
            content()
                .navigationDestination(for: Route.self) { route in
                    destination(route)
                }
                .sheet(item: $router.sheet) { sheet in
                    sheetContent(sheet)
                }
        }
        .environment(router)
        #endif
    }
}

public extension BaseNavigationContainer where SheetContent == EmptyView, CoverContent == EmptyView {
    init(
        router: NavigationRouter<Route, Sheet, Cover>,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder destination: @escaping (Route) -> Destination
    ) {
        self.init(
            router: router,
            content: content,
            destination: destination,
            sheet: { _ in EmptyView() },
            cover: { _ in EmptyView() }
        )
    }
}
