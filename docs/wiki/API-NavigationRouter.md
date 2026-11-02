# API — NavigationRouter

```swift
@MainActor @Observable
public final class NavigationRouter<
    Route: Hashable & Sendable,
    Sheet: Identifiable & Hashable & Sendable,
    Cover: Identifiable & Hashable & Sendable
>
```

`@MainActor` classes are implicitly `Sendable`, so the router can be captured from any context (see `send(_:)`).

Own the router with `@State` (or a long-lived model). Creating it inline in `body` recreates it on every render and loses the stack.

Single point of truth for stack, sheet, and cover state.

## State

| Property | Type | Meaning |
|---|---|---|
| `path` | `[Route]` | Navigation stack, root-first. Bind directly with `$router.path`. Writing it directly bypasses the `push` guards. |
| `sheet` | `Sheet?` | Active sheet; drives `.sheet(item:)`. At most one of `sheet` / `cover` is set through the router API. |
| `cover` | `Cover?` | Active full screen cover; drives `.fullScreenCover(item:)` (a sheet on macOS). |
| `maxDepth` | `Int` | Stack cap. Default `30`. Clamped to `>= 1` in the initializer and on every assignment. Lowering it does not trim an existing `path`. |

## Initializer

```swift
public init(
    initialPath: [Route] = [],
    initialSheet: Sheet? = nil,
    initialCover: Cover? = nil,
    maxDepth: Int = 30
)
```

```swift
let router = NavigationRouter<AppRoute, AppSheet, AppCover>()
let deepLink = NavigationRouter<AppRoute, AppSheet, AppCover>(
    initialPath: [.profile, .detail(id: 7)]   // truncated to maxDepth
)
let shallow = NavigationRouter<AppRoute, AppSheet, AppCover>(maxDepth: 5)
```

## Stack operations

### `push(_:)`

```swift
@discardableResult
public func push(_ route: Route) -> Bool
```

Returns `false` when the push is rejected, and logs the reason through `os.Logger` (subsystem `BaseNavigationStack`).

- Rejected when `path.count >= maxDepth`.
- **Duplicate-top guard**: if `path.last == route`, the push is ignored. Protects against double taps / repeated async dispatches producing duplicated screens. It is not time-based: a flow that legitimately pushes the same value twice in a row needs distinct values (e.g. include a step index).
- Equality is the route's `Hashable`/`Equatable` conformance — for enum routes with associated values, same case + same values means duplicate.

```swift
router.push(.detail(id: 42))   // path == [.detail(id: 42)]
router.push(.detail(id: 42))   // ignored — duplicate of top
router.push(.detail(id: 43))   // pushed
```

Note: only the *top* is compared. Pushing A → B → A is allowed.

### `pop()`

```swift
public func pop()
```

Pops topmost screen. No-op on empty path.

### `pop(count:)`

```swift
public func pop(count: Int)
```

Pops up to `count` screens: `min(count, path.count)`. Ignores non-positive counts. Over-run empties the stack safely.

```swift
router.pop(count: 2)  // remove 2
router.pop(count: 99) // empty the stack
```

### `popToRoot()`

```swift
public func popToRoot()
```

Clears `path`, `sheet`, and `cover`. Full reset to root.

### `replacePath(_:)`

```swift
@discardableResult
public func replacePath(_ newPath: [Route]) -> Bool
```

Replaces the whole stack (e.g. auth switch, deep-link jump) and dismisses any active sheet/cover. Keeps the first `maxDepth` routes and returns `false` when it had to truncate, so a deep link longer than `maxDepth` does not land on its final screen — check the result or raise `maxDepth`.

```swift
router.replacePath([.profile])  // sheet/cover nil, path == [.profile]
```

## Modal operations

### `present(sheet:)`

```swift
@discardableResult
public func present(sheet: Sheet) -> Bool
```

Sets `sheet`. Setting a new value while one is presented replaces it. Rejected (`false`) while a cover is presented: SwiftUI cannot present both from the same view. To show a sheet on top of a cover, give the cover its own router (see [[Nested-and-Tab-Navigation]]).

### `present(cover:)`

```swift
@discardableResult
public func present(cover: Cover) -> Bool
```

Sets `cover`. On iOS/tvOS/watchOS/visionOS rendered as `.fullScreenCover(item:)`; on macOS as a sheet. Rejected (`false`) while a sheet is presented.

### `dismiss()`

```swift
public func dismiss()
```

Ladder, first match wins:

1. `sheet != nil` → clear sheet.
2. `cover != nil` → clear cover.
3. else → pop one screen.
4. else → no-op.

Use this for a generic "back/close" button that works from any context.

### `dismissModals()`

```swift
public func dismissModals()
```

Clears `sheet` and `cover` without touching `path`.

## Background dispatch

### `send(_:)`

```swift
@discardableResult
nonisolated public func send(_ action: @escaping @MainActor (NavigationRouter) -> Void) -> Task<Void, Never>
```

Safe entry point from non-main actors. Wraps the mutation in `Task { @MainActor in ... }` and returns that task. The mutation runs asynchronously, so separate `send` calls are not guaranteed to run in call order — `await` the returned task (`await router.send { ... }.value`) when ordering matters. From code already on the main actor, call the methods directly.

```swift
Task.detached {
    let user = try await api.fetchUser()
    router.send { r in
        r.push(.detail(id: user.id))
    }
}
```

`send` itself is `nonisolated`, so it can be called from any context. The closure runs on the main actor; `self` is captured safely.

## Threading and `maxDepth` guard

- All mutable access is `@MainActor` isolated. There is no internal lock; correctness comes from actor isolation.
- `maxDepth` prevents runaway stacks (and SwiftUI layout warnings) from loops or repeated deep links. It applies to `push` and `replacePath`; `pop` etc. always allowed.

## Test example

```swift
@MainActor
func testCapAndDebounce() {
    let router = NavigationRouter<AppRoute, AppSheet, AppCover>(maxDepth: 2)
    router.push(.profile)
    assert(router.push(.profile) == false)        // duplicate of top
    router.push(.detail(id: 1))                   // depth 2
    assert(router.push(.detail(id: 2)) == false)  // rejected by maxDepth
    assert(router.path == [.profile, .detail(id: 1)])

    router.pop(count: 10)
    assert(router.path.isEmpty)
}
```
