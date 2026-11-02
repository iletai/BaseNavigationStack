# Changelog

All notable changes to this project are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [SemVer](https://semver.org).

## [Unreleased]

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
