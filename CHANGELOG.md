# Changelog

All notable changes to this project are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [SemVer](https://semver.org).

## [Unreleased]

### Added
- Opt-in zoom transitions: `router.push(_:zoomFrom:)` plus `View.baseNavigationTransitionSource(id:)`. Uses `navigationTransition(.zoom)` on iOS 18+; earlier OS versions and other platforms fall back to the default push.
- `SheetOptions` and `SheetPresentable`: a `Sheet` value that conforms carries its detents, drag indicator, corner radius, background interaction and interactive-dismiss setting; `navigationRouter(...)` applies them. Non-conforming sheets are unchanged.

### Fixed
- `View.navigationRouter(...)` on a hand-built `NavigationStack`: pushed destinations crashed when reading the router from `@Environment`, because `.environment(router)` was applied inside the stack. The router is now injected into every pushed destination (sheets and covers already inherited it). `BaseNavigationContainer` was not affected.

### Added
- Example app UI tests (`NavigationStackExampleUITests`) covering push/pop, nested sheet stack, full screen cover, background `send`, the modifier recipe (pushed screen and sheet), duplicate-push guard, `maxDepth` truncation, and sheet rejection while a cover is shown. CI runs them and attaches screenshots to the result bundle.

## [2.0.0] - 2026-11-02

### Added
- `NavigationRouter<Route, Sheet, Cover>`: one `@MainActor @Observable` router for stack, sheet, and cover.
- `BaseNavigationContainer` and `View.navigationRouter(...)`.
- `maxDepth` stack cap (default 30) and duplicate-top push guard.
- `push`, `replacePath`, `present(sheet:)`, `present(cover:)` return `Bool` (`@discardableResult`) and log rejections via `os.Logger`.
- `send(_:)` returns its `Task` so callers can await the main-actor mutation.
- tvOS 17, watchOS 10, and visionOS 1 declared in `Package.swift`.

### Changed
- **Breaking:** `swift-tools-version` 6.0 (Xcode 16+), Swift 6 language mode; minimums iOS 17 / macOS 14.
- Because `push`/`present`/`replacePath` now return `Bool`, generic single-expression closures such as `MainActor.run { router.push(x) }` infer `Bool` and warn about an unused result. Call `await router.push(x)` directly, or write `_ = router.push(x)`.
- macOS presents covers as sheets instead of ignoring them.
- A sheet and a cover can no longer be presented at the same time through the router API.
- `maxDepth` is clamped to `>= 1` on every assignment (assigning a negative value previously crashed `replacePath`); `initialPath` is truncated to `maxDepth`.

### Removed
- **Breaking:** public `Collection.subscript(safe:)` and `Array.removeLastSafe()`.
- Redundant `@unchecked Sendable` on `@MainActor` classes.

### Fixed
- v1 `BaseNavigationStack.dismiss()` pops a single-screen stack; `replaceNavigationStack(path:)` clears active modals.

## [1.0.3] - 2023-12-24

Last 1.x release (`BaseNavigationStack<ScreenView>` + `BaseViewProtocol`).

[Unreleased]: https://github.com/iletai/BaseNavigationStack/compare/2.0.0...develop
[2.0.0]: https://github.com/iletai/BaseNavigationStack/compare/1.0.3...2.0.0
[1.0.3]: https://github.com/iletai/BaseNavigationStack/releases/tag/1.0.3
