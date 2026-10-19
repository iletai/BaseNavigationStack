//
//  NavigationRouter.swift
//  BaseNavigationStack
//
//  Created by Claude on 19/10/2026.
//

import SwiftUI
import Observation

/// Modern 2.0 Router for SwiftUI Data-Driven Navigation.
/// Unifies Stack navigation, Sheet presentation, and FullScreenCover in a single point of truth.
@MainActor
@Observable
public final class NavigationRouter<Route: Hashable & Sendable, Sheet: Identifiable & Hashable & Sendable, Cover: Identifiable & Hashable & Sendable>: @unchecked Sendable {
    public var path: [Route] = []
    public var sheet: Sheet?
    public var cover: Cover?

    /// Maximum stack depth allowed to prevent memory bloating and SwiftUI layout warnings.
    /// Default is 30.
    public var maxDepth: Int

    public init(
        initialPath: [Route] = [],
        initialSheet: Sheet? = nil,
        initialCover: Cover? = nil,
        maxDepth: Int = 30
    ) {
        self.path = initialPath
        self.sheet = initialSheet
        self.cover = initialCover
        self.maxDepth = max(1, maxDepth)
    }

    /// Pushes a new route onto the navigation stack.
    /// Deduplicates immediate subsequent pushes of the identical route to prevent UI glitches.
    /// Rejects push if current stack depth reaches `maxDepth`.
    public func push(_ route: Route) {
        guard path.count < maxDepth else { return }
        if path.last != route {
            path.append(route)
        }
    }

    /// Pops the topmost screen from the navigation stack.
    public func pop() {
        _ = path.popLast()
    }

    /// Pops back `count` screens from the stack safely.
    public func pop(count: Int) {
        let itemsToRemove = min(count, path.count)
        guard itemsToRemove > 0 else { return }
        path.removeLast(itemsToRemove)
    }

    /// Pops back to the root screen of the navigation stack.
    public func popToRoot() {
        sheet = nil
        cover = nil
        path.removeAll()
    }

    /// Replaces the entire stack with a new path, clearing any active sheets/covers.
    public func replacePath(_ newPath: [Route]) {
        sheet = nil
        cover = nil
        path = Array(newPath.prefix(maxDepth))
    }

    /// Presents a modal sheet.
    public func present(sheet: Sheet) {
        self.sheet = sheet
    }

    /// Presents a full screen cover.
    public func present(cover: Cover) {
        self.cover = cover
    }

    /// Dismisses active sheet/cover if any, otherwise pops top screen from navigation stack.
    public func dismiss() {
        if sheet != nil {
            sheet = nil
        } else if cover != nil {
            cover = nil
        } else {
            _ = path.popLast()
        }
    }

    /// Clears all modals without altering the underlying navigation stack.
    public func dismissModals() {
        sheet = nil
        cover = nil
    }

    /// Safely dispatches a navigation mutation from any background Task or external actor context.
    nonisolated public func send(_ action: @escaping @MainActor (NavigationRouter) -> Void) {
        Task { @MainActor in
            action(self)
        }
    }
}
