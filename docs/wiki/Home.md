# BaseNavigationStack 2.0

Modern, type-safe, data-driven navigation for SwiftUI (iOS 17+ / macOS 14+, Swift 6).

`BaseNavigationStack` unifies Stack pushes, Sheets, and FullScreenCovers under a single `@MainActor @Observable` router — no fragmented `@State`, no external dependencies.

## Goals

- **Single source of truth** — one router owns `path`, `sheet`, `cover`.
- **Zero dependencies** — pure SwiftUI + Observation, nothing else in `Package.swift`.
- **Strict Concurrency** — Swift 6 with `StrictConcurrency` upcoming feature; router is `@MainActor` isolated and `Sendable`.
- **O(1)-style mutations** — stack state is a plain `[Route]` array; duplicate push is one equality check against `path.last`, pops are bounded with `min(count, path.count)`. Unit-testable with zero UI test overhead.
- **Race-condition guard** — rapid identical taps collapse into one push (debounce), `maxDepth` caps stack growth.
- **Nested ready** — independent routers per Tab and per modal.

## Design philosophy

1. Data-driven: navigation state is data, SwiftUI renders it. Programmatic navigation == mutate an array.
2. Type-safe routes: `Route: Hashable & Sendable`, no string identifiers.
3. Safe by default: `pop()` on empty stack, `pop(count:)` over-run, duplicate pushes — all no-ops instead of crashes.
4. Testable: router logic is pure Swift, exercised in `Tests/BaseNavigationStackTests`.

## Architecture

```
NavigationRouter<Route, Sheet, Cover>   ← state (@Observable, @MainActor)
        │
BaseNavigationContainer                 ← declarative view (NavigationStack + destinations + modals)
        │
View.navigationRouter(...)              ← modifier alternative for custom stacks
```

## Pages

- [[Getting-Started]] — install + first router in 3 steps
- [[API-NavigationRouter]] — full router API
- [[API-BaseNavigationContainer]] — container view
- [[API-Modifiers-and-Helpers]] — modifiers, collection helpers, v1 layer
- [[Deep-Linking-and-URL-Handling]]
- [[Nested-and-Tab-Navigation]]
- [[Swift-6-Concurrency]]
- [[Migration-Guide-v1-to-v2]]
