<div align="center">

# BaseNavigationStack

**Type-safe, data-driven navigation for SwiftUI. One source of truth. Zero external dependencies.**

[![Swift Version](https://img.shields.io/badge/Swift-6.0-F05138.svg?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%2B%20%7C%20macOS%2014%2B%20%7C%20tvOS%2017%2B%20%7C%20watchOS%2010%2B%20%7C%20visionOS%201%2B-007AFF.svg?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com)
[![Strict Concurrency](https://img.shields.io/badge/Swift%206-Strict%20Concurrency%20Complete-34C759.svg?style=for-the-badge)](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-Zero-8E8E93.svg?style=for-the-badge)](#)
[![CI](https://img.shields.io/github/actions/workflow/status/iletai/BaseNavigationStack/ci.yml?branch=develop&style=for-the-badge&label=CI)](https://github.com/iletai/BaseNavigationStack/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

[Features](#features) • [Quickstart](#quickstart) • [Architecture](#architecture) • [API Cheat Sheet](#api-cheat-sheet) • [Advanced Recipes](#advanced-recipes) • [Example App](#example-app) • [Docs & Wiki](#docs--wiki) • [Contributing](#contributing) • [License](#license)

<sub>Minimums declared in `Package.swift`: iOS 17+, macOS 14+. tvOS / watchOS / visionOS compile via conditional code paths (full screen cover applied only where supported).</sub>

</div>

## Why BaseNavigationStack?

SwiftUI's built-in navigation is powerful, but state tends to sprawl across views. `BaseNavigationStack` unifies **push**, **sheet**, and **full screen cover** transitions under a single, observable router — keeping navigation predictable, testable, and safe under concurrency.

## Comparison

| Aspect | Vanilla SwiftUI Navigation | **BaseNavigationStack 2.0** |
| --- | --- | --- |
| **State ownership** | Scattered `@State` / bindings across views | **Single Source of Truth** via `NavigationRouter` |
| **Modal + Stack** | Managed separately with easy desync | **Unified** `path`, `sheet`, `cover` in one router |
| **Type-safety** | Manual `navigationDestination` wiring, error-prone routes | **Strongly typed** `Route`, `Sheet`, `Cover` (`Hashable & Sendable`) |
| **Race conditions** | Double-taps can push duplicates | **Auto-debounce** guards against immediate duplicate pushes |
| **Deep linking / programmatic nav** | Hard to coordinate across the tree | **Centralized API**: `push`, `pop`, `popToRoot`, `present`, `dismiss`, `replacePath` |
| **Concurrency** | Easy to call from wrong isolation | **Swift 6 ready** — `@MainActor` + `send(_:)` for safe cross-actor dispatch |
| **Testability** | Often requires UI tests | **Headless-testable** — inspect pure `[Route]` arrays with no UI overhead |
| **Nested flows** | Complex and easy to leak state | **Isolated sub-routers** per sheet/tab with independent lifecycles |

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BaseNavigationContainer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────────┐   │
│  │ NavigationStack│  │ navigationDestination │  │ sheet(item:) │  │ fullScreenCover   │   │
│  │   (path)       │  │   (Route)             │  │  (Sheet)     │  │ (Cover, iOS/tvOS/ │   │
│  └─────────────┘  └─────────────┘  └─────────────┘  │  visionOS/watchOS)│   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │ injects .environment(router)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              NavigationRouter<Route, Sheet, Cover>          │
│  path: [Route]  │  sheet: Sheet?  │  cover: Cover?  │  maxDepth: Int         │
│  push / pop / popToRoot / replacePath / present / dismiss / dismissModals    │
│  send(_:) for actor-safe dispatch   │  debounce + depth guard              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                            Any View via @Environment
```

**Flow:** `Route Push` → **Debounce/Depth Guard** → `NavigationStack` → `navigationDestination` → `Sheet` / `FullScreenCover` → **Deep Link** via central router/state.

## Features

- **Swift 6 Strict Concurrency** — Fully `@MainActor`, `Sendable`-compliant, ready for complete concurrency checking.
- **Zero External Dependencies** — Built on native SwiftUI, `Observation`, and Foundation only.
- **Unified Multi-Modal Routing** — Manage stack, sheet, and full screen cover from one `@Observable` router.
- **Auto-Debounce Rapid Taps** — Prevents duplicate pushes when the same route hits back-to-back.
- **Stack Depth Protection** — `maxDepth` guard (default `30`) helps avoid layout recursion/memory pressure.
- **Actor-Safe Navigation** — `send(_:)` lets you dispatch navigation safely from `Task.detached`, background actors, or async callbacks.
- **Nested & Tabbed Navigation** — Spin up isolated routers per tab or inside sheets for independent flows.
- **Headless Unit-Testable** — Mutate router state directly in tests; assert on `[Route]`, modals, and transitions.
- **Cross-Platform Aware** — Works across iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, visionOS 1+. Full-screen covers are applied on platforms that support them.
- **Backward Compatible (v1.x)** — `BaseNavigationStack<ScreenView>` remains supported with fixes for `dismiss()`, `replaceNavigationStack(path:)`, and `@Bindable` compatibility.

## Quickstart

### 1) Add the package

**Swift Package Manager**

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/iletai/BaseNavigationStack.git", from: "2.0.0")
],
targets: [
    .target(name: "YourTarget", dependencies: ["BaseNavigationStack"])
]
```

Or in Xcode: `File > Add Package Dependencies...` and paste the repo URL.

### 2) Define type-safe routes

```swift
import Foundation

enum AppRoute: Hashable, Sendable {
    case detail(id: Int)
    case profile(userID: String)
}

struct AppSheet: Identifiable, Hashable, Sendable {
    let id: String
}

struct AppCover: Identifiable, Hashable, Sendable {
    let id: String
}

typealias AppRouter = NavigationRouter<AppRoute, AppSheet, AppCover>
```

### 3) Wire up the container

```swift
import SwiftUI
import BaseNavigationStack

struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        BaseNavigationContainer(
            router: router,
            content: {
                HomeView()
            },
            destination: { route in
                switch route {
                case .detail(let id):
                    DetailView(id: id)
                case .profile(let userID):
                    ProfileView(userID: userID)
                }
            },
            sheet: { sheet in
                LoginSheet(id: sheet.id)
            },
            cover: { cover in
                OnboardingCover(id: cover.id)
            }
        )
    }
}
```

> **Already have a `NavigationStack`?** Use the modifier instead: `.navigationRouter(router, destination:sheet:cover:)` to attach routing to your existing hierarchy. See [Advanced Recipes](#advanced-recipes).

### 4) Navigate from anywhere

```swift
import SwiftUI
import BaseNavigationStack

struct HomeView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Button("Push Detail") { router.push(.detail(id: 42)) }
            Button("Present Sheet") { router.present(sheet: AppSheet(id: "login")) }
            Button("Present Full Screen Cover") { router.present(cover: AppCover(id: "onboarding")) }
            Button("Pop") { router.pop() }
            Button("Pop to Root") { router.popToRoot() }
            Button("Dismiss (Sheet/Cover/Stack)") { router.dismiss() }
        }
        .navigationTitle("Home")
    }
}
```

## Advanced Recipes

### Tab Navigation with Isolated Routers

Keep each tab's stack independent. Dismissing/modals in one tab won't affect others.

```swift
struct TabRootView: View {
    @State private var homeRouter = AppRouter()
    @State private var searchRouter = AppRouter()

    var body: some View {
        TabView {
            BaseNavigationContainer(router: homeRouter) {
                HomeView()
            } destination: { HomeDestination($0) }
            .tabItem { Label("Home", systemImage: "house") }

            BaseNavigationContainer(router: searchRouter) {
                SearchView()
            } destination: { SearchDestination($0) }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
        }
    }
}
```

### Sheet with its own Sub-Router

Perfect for multi-step flows inside a modal without polluting the parent stack.

```swift
struct FlowSheetView: View {
    @State private var subRouter = AppRouter()
    @Environment(AppRouter.self) private var parentRouter

    var body: some View {
        BaseNavigationContainer(
            router: subRouter,
            content: { SheetStartView() },
            destination: { route in
                switch route {
                case .detail(let id): SheetDetailView(id: id)
                case .profile(let userID): SheetProfileView(userID: userID)
                }
            }
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { parentRouter.dismiss() }
            }
        }
    }
}
```

### Deep Linking / Async Navigation

Use `send(_:)` to navigate safely from async work or background actors.

```swift
func handleDeepLink(_ url: URL) async {
    // Parse route from URL...
    let route = AppRoute.detail(id: 123)

    await MainActor.run {
        router.push(route)
    }

    // Or from a detached task/actor:
    Task.detached {
        router.send { r in
            r.popToRoot()
            r.push(.profile(userID: "u_123"))
        }
    }
}
```

### Attach to an Existing NavigationStack

```swift
struct CustomRootView: View {
    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            ContentView()
                .navigationRouter(
                    router,
                    destination: { route in DestinationView(route: route) },
                    sheet: { sheet in SheetView(sheet: sheet) },
                    cover: { cover in CoverView(cover: cover) }
                )
        }
    }
}
```

## API Cheat Sheet

### `NavigationRouter<Route, Sheet, Cover>`

| Method / Property | Type | Description | Complexity |
| --- | --- | --- | --- |
| `init(initialPath:initialSheet:initialCover:maxDepth:)` | Initializer | Create router with optional initial state. `maxDepth` clamped to >= 1 (default `30`). | O(1) |
| `path` | `[Route]` | Active navigation stack. Bind to `NavigationStack(path:)`. | O(1) access |
| `sheet` | `Sheet?` | Currently presented sheet. | O(1) |
| `cover` | `Cover?` | Currently presented full screen cover. | O(1) |
| `maxDepth` | `Int` | Maximum allowed stack depth. `push` is a no-op if `path.count >= maxDepth`. | O(1) |
| `push(_:)` | `func(Route)` | Push route if different from last and under `maxDepth` (auto-debounce). | O(1) |
| `pop()` | `func()` | Pop top route if exists. | O(1) |
| `pop(count:)` | `func(Int)` | Safely pop up to `count` routes. | O(k), k = removed |
| `popToRoot()` | `func()` | Clear path and dismiss all modals. | O(n) path clear |
| `replacePath(_:)` | `func([Route])` | Replace stack with new path (truncated to `maxDepth`), clears modals. | O(n) |
| `present(sheet:)` | `func(Sheet)` | Present a sheet. | O(1) |
| `present(cover:)` | `func(Cover)` | Present a full screen cover. | O(1) |
| `dismiss()` | `func()` | Dismiss ladder: sheet → cover → pop top route. No-op on empty stack. | O(1) |
| `dismissModals()` | `func()` | Clear sheet/cover without touching stack. | O(1) |
| `send(_:)` | `nonisolated func(@MainActor (NavigationRouter) -> Void)` | Dispatch navigation from any actor/context via `Task { @MainActor in ... }`. | O(1) dispatch |

### `BaseNavigationContainer`

| Initializer | Notes |
| --- | --- |
| `init(router:content:destination:sheet:cover:)` | Full container: wraps `NavigationStack`, `navigationDestination`, `.sheet`, `.fullScreenCover` (platform-aware), injects `.environment(router)`. |
| `init(router:content:destination:)` where `SheetContent == EmptyView`, `CoverContent == EmptyView` | Stack-only convenience initializer. |

### `View.navigationRouter(_:)`

| Overload | Notes |
| --- | --- |
| `navigationRouter(_:destination:sheet:cover:)` | Attach routing to an existing view/hierarchy. Use inside your own `NavigationStack(path:)`. Injects `.environment(router)`. |
| `navigationRouter(_:destination:)` | Stack-only convenience overload. |

### Legacy (v1.x) — `BaseNavigationStack<ScreenView>`

| Method | Notes |
| --- | --- |
| `pushToView(_:)` | Debounced push with duplicate prevention. |
| `popBack()` | Safe pop via `removeLastSafe()`. |
| `navigateToRoot()` | Clears modals and stack. |
| `replaceNavigationStack(path:)` | Replaces path and clears modals. |
| `presentSheet(_:)` / `presentFullScreen(_:)` | Modal presentation. |
| `dismiss()` | Sheet → FullScreen → Stack → parent binding fallback. |
| `handleOpenURL(url:)` | Route via optional `urlHandler`. |

## Example App

Explore a live, interactive showcase in [`NavigationStackExample/`](NavigationStackExample/).

**Tabs included:**

- **Stack Explorer** — Push/pop, breadcrumb trail, depth counter, present sheet/cover, pop to root.
- **Async & Concurrency Lab** — Background async navigation via `send(_:)`, rapid-tap stress test to verify debounce/guards.

Run it in Xcode by opening `NavigationStackExample/NavigationStackExample.xcodeproj` or via the scheme in your workspace.

## Testing

Run the full test suite:

```bash
# With SwiftPM
swift test

# With coverage
swift test --enable-code-coverage

# iOS Simulator (example from CI)
SIM_ID=$(xcrun simctl list devices available | grep -E "iPhone" | head -1 | grep -o -E "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}")
xcodebuild test -scheme BaseNavigationStack -destination "id=$SIM_ID" CODE_SIGNING_ALLOWED=NO
```

**Coverage includes:** push/pop/popToRoot/replace, duplicate-debounce, dismiss ladder, stack depth guard, async `send` from background, nested sub-routers, tab isolation, container/modifier initialization.

## Docs & Wiki

- **Design Specs:** [`docs/superpowers/specs/`](docs/superpowers/specs/) — Container, async ergonomics, performance goals.
- **Implementation Plans:** [`docs/superpowers/plans/`](docs/superpowers/plans/) — Step-by-step rollout notes.
- **GitHub Wiki:** [BaseNavigationStack Wiki](https://github.com/iletai/BaseNavigationStack/wiki) — Extended guides, migration notes, and FAQs (if enabled).
- **Issues:** [Report bugs / request features](https://github.com/iletai/BaseNavigationStack/issues)
- **Discussions:** [Community Q&A](https://github.com/iletai/BaseNavigationStack/discussions)

## Contributing

Contributions are welcome!

1. **Fork** the repo and create a feature branch off `develop`.
2. **Follow style** — Match existing Swift style; CI runs `swiftlint --strict`.
3. **Test** — Add/update tests for behavior changes. Run `swift test` locally.
4. **Commit** — Use clear, conventional commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`).
5. **Open a PR** — Target `develop` with a concise description and test notes.

See [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md) and [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/) for details.

## License

Released under the [MIT License](LICENSE). Copyright (c) 2023 Tài Lê.
