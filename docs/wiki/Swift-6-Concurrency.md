# Swift 6 Concurrency

Package is built with `swift-tools-version: 6.0` and `.enableUpcomingFeature("StrictConcurrency")`.

## `@MainActor` isolation

`NavigationRouter` (and legacy `BaseNavigationStack`) are `@MainActor`:

```swift
@MainActor
@Observable
public final class NavigationRouter<Route: Hashable & Sendable, ...>: @unchecked Sendable
```

Consequences:

- All mutations (`push`, `pop`, `present`, …) run on the main actor. Calling them from a background task directly is a compile error — use `send(_:)`.
- SwiftUI reads (`path`, `sheet`, `cover`) happen on the main thread anyway; no extra hops.
- Tests must be `@MainActor`:

```swift
@MainActor
final class NavigationRouterTests: XCTestCase {
    func testPushAndPop() {
        let router = NavigationRouter<TestRoute, TestSheet, TestCover>()
        router.push(.detail(id: 1))
        XCTAssertEqual(router.path, [.detail(id: 1)])
    }
}
```

## `send(_:)` — crossing actor boundaries

```swift
nonisolated public func send(
    _ action: @escaping @MainActor (NavigationRouter) -> Void
) {
    Task { @MainActor in
        action(self)
    }
}
```

- `send` is `nonisolated` → callable from any actor/Task.
- The closure is `@MainActor`-typed → runs isolated on main after the hop.
- The class declares `@unchecked Sendable`: safety relies on main-actor isolation of all stored state (the standard `@MainActor` class pattern). Do not add non-isolated mutable storage.

```swift
Task.detached {
    let items = try await api.fetch()
    router.send { r in
        for item in items {
            r.push(.detail(id: item.id))   // runs on MainActor
        }
    }
}
```

## `@Observable` runtime

```swift
import Observation

@Observable @MainActor
final class NavigationRouter<...> { ... }
```

- Observation tracks `path`/`sheet`/`cover` access during `body` evaluation; writes invalidate only dependent views — no `objectWillChange` overhead.
- `@Bindable var bindableRouter = router` inside the modifier/container produces `$router.path` bindings for `NavigationStack(path:)` and `.sheet(item:)`.
- `@Observable` + `@MainActor` is fully supported under strict concurrency; no `@Published`, no Combine.

## Sendable constraints on generics

| Type | Constraints | Why |
|---|---|---|
| `Route` | `Hashable & Sendable` | stored in `@MainActor` array, compared per push, may cross into `navigationDestination` |
| `Sheet` / `Cover` | `Identifiable & Hashable & Sendable` | SwiftUI `item:` APIs + may be created off-main before `send` |

Practical impact: route enums and modal models must be value types (or otherwise correctly `Sendable`). `struct`, `enum` with associated `Sendable` values — fine. Non-Sendable classes as routes — compiler error, use `id` payloads instead:

```swift
// Bad: class payload
case user(UserClass)

// Good: stable identifier
case user(id: UUID)
```

## Data-race safety guarantees

1. Single writer domain: main actor only; no locks, no queues.
2. Rapid-tap race: `push` compares `path.last` — duplicate collapses (debounce).
3. Background dispatch race: `send` serializes onto main actor.
4. Runaway stack: `maxDepth` caps depth at push time.
5. Empty-stack ops: `pop()`, `pop(count:)`, `removeLastSafe()` are no-ops, never traps.

## Build flags reference

`Package.swift`:

```swift
swiftSettings: [
    .enableUpcomingFeature("StrictConcurrency")
]
```

App targets using Swift 6 language mode should set `SWIFT_STRICT_CONCURRENCY = complete` in build settings to match.
