# Swift 6 Concurrency

Package is built with `swift-tools-version: 6.0`, which compiles in the Swift 6 language mode (complete strict concurrency checking) by default. No extra flags are needed.

## `@MainActor` isolation

`NavigationRouter` (and legacy `BaseNavigationStack`) are `@MainActor`:

```swift
@MainActor
@Observable
public final class NavigationRouter<Route: Hashable & Sendable, ...>
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
@discardableResult
nonisolated public func send(
    _ action: @escaping @MainActor (NavigationRouter) -> Void
) -> Task<Void, Never> {
    Task { @MainActor in
        action(self)
    }
}
```

- `send` is `nonisolated` → callable from any actor/Task.
- The closure is `@MainActor`-typed → runs isolated on main after the hop.
- `@MainActor` classes are implicitly `Sendable`, so capturing `router` in a detached task is checked by the compiler — no `@unchecked` escape hatch.
- The mutation runs asynchronously. Separate `send` calls are not guaranteed to run in call order; `await router.send { ... }.value` when ordering matters.

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
3. Background dispatch race: `send` hops onto the main actor; await the returned task to order calls.
4. Runaway stack: `maxDepth` caps depth at push time.
5. Empty-stack ops: `pop()`, `pop(count:)`, `dismiss()` are no-ops, never traps.
6. Invalid configuration: `maxDepth` is clamped to `>= 1` on every assignment.

## Build flags reference

`Package.swift` uses `swift-tools-version: 6.0` with no extra `swiftSettings`; the Swift 6 language mode already enables complete concurrency checking.

App targets should set `SWIFT_VERSION = 6.0` (the example app does). Apps still on Swift 5 mode can use the package, but get weaker checking in their own code.
