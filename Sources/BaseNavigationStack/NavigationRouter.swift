//
//  NavigationRouter.swift
//  BaseNavigationStack
//
//  Created by Claude on 19/10/2026.
//

import SwiftUI
import Observation
import os

/// Modern 2.0 Router for SwiftUI Data-Driven Navigation.
/// Unifies Stack navigation, Sheet presentation, and FullScreenCover in a single point of truth.
///
/// Own the router with `@State` (or a long-lived model). Creating it inline inside `body`
/// recreates it on every render and loses the stack.
@MainActor
@Observable
public final class NavigationRouter<Route: Hashable & Sendable, Sheet: Identifiable & Hashable & Sendable, Cover: Identifiable & Hashable & Sendable> {
    /// Current stack. Bound to `NavigationStack(path:)`. Writing it directly bypasses
    /// the `push` duplicate and `maxDepth` guards.
    public var path: [Route] = []
    /// Active sheet. Only one of `sheet` / `cover` is presented at a time.
    public var sheet: Sheet?
    /// Active full screen cover. Presented as a sheet on macOS.
    public var cover: Cover?

    /// Maximum stack depth allowed to prevent memory bloating and SwiftUI layout warnings.
    /// Default is 30. Always clamped to `>= 1`.
    public var maxDepth: Int {
        didSet { if maxDepth < 1 { maxDepth = 1 } }
    }

    public init(
        initialPath: [Route] = [],
        initialSheet: Sheet? = nil,
        initialCover: Cover? = nil,
        maxDepth: Int = 30
    ) {
        self.maxDepth = max(1, maxDepth)
        self.path = Array(initialPath.prefix(self.maxDepth))
        self.sheet = initialSheet
        self.cover = initialSheet == nil ? initialCover : nil
    }

    /// Pushes a new route onto the navigation stack.
    /// Ignores a route equal to the current top (guards against double taps), and rejects
    /// the push once the stack reaches `maxDepth`.
    /// - Returns: `false` if the push was rejected.
    @discardableResult
    public func push(_ route: Route) -> Bool {
        guard path.count < maxDepth else {
            Self.logger.warning("push rejected: stack reached maxDepth (\(self.maxDepth))")
            return false
        }
        guard path.last != route else {
            Self.logger.debug("push ignored: route equals current top")
            return false
        }
        path.append(route)
        return true
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
    /// - Returns: `false` if `newPath` was longer than `maxDepth` and got truncated.
    @discardableResult
    public func replacePath(_ newPath: [Route]) -> Bool {
        sheet = nil
        cover = nil
        path = Array(newPath.prefix(maxDepth))
        guard newPath.count <= maxDepth else {
            Self.logger.warning("replacePath truncated \(newPath.count) routes to maxDepth (\(self.maxDepth))")
            return false
        }
        return true
    }

    /// Presents a modal sheet. Rejected while a cover is presented, because SwiftUI cannot
    /// present both from the same view. Present from the cover's own router instead.
    /// - Returns: `false` if the presentation was rejected.
    @discardableResult
    public func present(sheet: Sheet) -> Bool {
        guard cover == nil else {
            Self.logger.warning("present(sheet:) rejected: a cover is already presented")
            return false
        }
        self.sheet = sheet
        return true
    }

    /// Presents a full screen cover. Rejected while a sheet is presented.
    /// - Returns: `false` if the presentation was rejected.
    @discardableResult
    public func present(cover: Cover) -> Bool {
        guard sheet == nil else {
            Self.logger.warning("present(cover:) rejected: a sheet is already presented")
            return false
        }
        self.cover = cover
        return true
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

    /// Dispatches a navigation mutation onto the main actor from any background Task or actor.
    /// The mutation runs asynchronously; `await` the returned task if ordering matters.
    @discardableResult
    nonisolated public func send(_ action: @escaping @MainActor (NavigationRouter) -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            action(self)
        }
    }

    private static var logger: Logger {
        Logger(subsystem: "BaseNavigationStack", category: "NavigationRouter")
    }
}
