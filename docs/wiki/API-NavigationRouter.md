# API — NavigationRouter

```swift
@MainActor @Observable
public final class NavigationRouter<
    Route: Hashable & Sendable,
    Sheet: Identifiable & Hashable & Sendable,
    Cover: Identifiable & Hashable & Sendable
>: @unchecked Sendable
```

Single point of truth for stack, sheet, and cover state.

## State

| Property | Type | Meaning |
|---|---|---|
| `path` | `[Route]` | Navigation stack, root-first. Bind directly with `$router.path`. |
| `sheet` | `Sheet?` | Active sheet; drives `.sheet(item:)`. |
| `cover` | `Cover?` | Active full screen cover; drives `.fullScreenCover(item:)`. |
| `maxDepth` | `Int` | Stack cap. Default `30`. Initializer clamps to `max(1, maxDepth)`. |

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
    initialPath: [.profile, .detail(id: 7)]
)
let shallow = NavigationRouter<AppRoute, AppSheet, AppCover>(maxDepth: 5)
```

## Stack operations

### `push(_:)`

```swift
public func push(_ route: Route)
```

- Guards `path.count < maxDepth`; silently drops when at cap.
- **Debounce**: if `path.last == route`, the push is ignored. Protects against double taps / repeated async dispatches producing duplicated screens.
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
public func replacePath(_ newPath: [Route])
```

Replaces the whole stack (e.g. auth switch, deep-link jump) and dismisses any active sheet/cover. Truncates to `maxDepth` via `prefix(maxDepth)`.

```swift
router.replacePath([.profile])  // sheet/cover nil, path == [.profile]
```

## Modal operations

### `present(sheet:)`

```swift
public func present(sheet: Sheet)
```

Sets `sheet`. Setting a new value while one is presented replaces it.

### `present(cover:)`

```swift
public func present(cover: Cover)
```

Sets `cover`. On iOS/tvOS/watchOS/visionOS rendered as `.fullScreenCover(item:)`.

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
nonisolated public func send(_ action: @escaping @MainActor (NavigationRouter) -> Void)
```

Safe entry point from non-main actors. Wraps the mutation in `Task { @MainActor in ... }`.

```swift
Task.detached {
    let user = try await api.fetchUser()
    router.send { r in
        r.push(.profile(user))
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
    router.push(.profile)          // debounced
    router.push(.detail(id: 1))    // depth 2
    router.push(.detail(id: 2))    // rejected by maxDepth
    assert(router.path == [.profile, .detail(id: 1)])

    router.pop(count: 10)
    assert(router.path.isEmpty)
}
```
