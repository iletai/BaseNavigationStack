# Migration Guide — v1 → v2

v1 bound navigation logic to each screen (`BaseViewProtocol`). v2 splits **state** (`NavigationRouter`) from **mapping** (container closures). v1 still compiles — migrate incrementally, screen by screen.

## Mapping table

| v1 | v2 |
|---|---|
| `BaseNavigationStack<ScreenView>` | `NavigationRouter<Route, Sheet, Cover>` |
| `BaseViewProtocol` screen model | plain `Hashable & Sendable` route enum |
| `withNavigationDestination()` on every case | one `destination:` closure in container |
| `withSheetDestination()` | `sheet:` closure |
| `withFullScreenDestination()` | `cover:` closure |
| `pushToView(_:)` | `push(_:)` |
| `popBack()` | `pop()` |
| `navigateToRoot()` | `popToRoot()` |
| `replaceNavigationStack(path:)` | `replacePath(_:)` |
| `presentSheet(_:)` | `present(sheet:)` |
| `presentFullScreen(_:)` | `present(cover:)` |
| `dismiss()` | `dismiss()` — same sheet → cover → pop ladder, without v1's final `isPresented = nil` step. Close a presented flow from the parent router instead. |
| `navigationPath` binding | `router.path` (`$router.path` via `@Bindable`) |
| `presentingSheet`, `presentingFullScreen` | `router.sheet`, `router.cover` |
| `urlHandler` / `handleOpenURL(url:)` | No router hook in v2: parse the URL yourself in `.onOpenURL` and call `replacePath(_:)`. See [[Deep-Linking-and-URL-Handling]]. |

## Before (v1)

```swift
enum Screen: BaseViewProtocol {
    case list
    case policy(URL)

    var id: String { /* ... */ }

    @MainActor func withNavigationDestination() -> some View {
        switch self {
        case .list: ListView()
        case .policy: PolicyView()
        }
    }
    // withSheetDestination(), withFullScreenDestination() ...
}

typealias BaseNavigation = BaseNavigationStack<Screen>

struct RootView: View {
    @State private var nav = BaseNavigation()

    var body: some View {
        NavigationStack(path: nav.navigationPath) {
            HomeView()
                .navigationDestination(for: Screen.self) { screen in
                    screen.withNavigationDestination()
                }
                .sheet(item: nav.presentingSheet) { $0.withSheetDestination() }
                .fullScreenCover(item: nav.presentingFullScreen) { $0.withFullScreenDestination() }
        }
        .environment(nav)
    }
}

struct HomeView: View {
    @Environment(BaseNavigation.self) private var nav
    var body: some View {
        Button("Policy") { nav.pushToView(.policy(url)) }
        Button("Back") { nav.popBack() }
    }
}
```

## After (v2)

```swift
enum AppRoute: Hashable, Sendable {
    case list
    case policy(URL)
}

struct AppSheet: Identifiable, Hashable, Sendable { let id: String }
struct AppCover: Identifiable, Hashable, Sendable { let id: String }

typealias AppRouter = NavigationRouter<AppRoute, AppSheet, AppCover>

struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        BaseNavigationContainer(
            router: router,
            content: { HomeView() },
            destination: { route in
                switch route {
                case .list: ListView()
                case .policy(let url): PolicyView(url: url)
                }
            },
            sheet: { sheet in SheetView(id: sheet.id) },
            cover: { cover in CoverView(id: cover.id) }
        )
    }
}

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    var body: some View {
        Button("Policy") { router.push(.policy(url)) }
        Button("Back") { router.pop() }
    }
}
```

## Step-by-step

1. Extract each v1 screen case into a route enum case. Move payloads into associated values (`policy(URL)` stays `policy(URL)`); the old `id` property becomes unnecessary.
2. Replace `with*Destination()` switches with a single `destination:` closure in the container. Delete `BaseViewProtocol` conformance.
3. Rename calls:
   - `pushToView(x)` → `push(x)`
   - `popBack()` → `pop()`
   - `navigateToRoot()` → `popToRoot()`
   - `replaceNavigationStack(path:)` → `replacePath(_:)`
   - `presentSheet(x)` / `presentFullScreen(x)` → `present(sheet:)` / `present(cover:)`
4. Replace `@Environment(BaseNavigation.self)` with `@Environment(AppRouter.self)`; update the typealias.
5. Replace `NavigationStack(path: nav.navigationPath)` + manual `.navigationDestination/.sheet/.fullScreenCover` chains with `BaseNavigationContainer` (or `.navigationRouter(...)`).
6. Build. The compiler flags every remaining v1 call site.

## Behavior changes to watch

| Behavior | v1 | v2 |
|---|---|---|
| `dismiss()` on a 1-item stack | no-op in 1.0.x (required 2+ items) | pops it |
| Duplicate push | ignored silently | ignored; `push` returns `false` |
| Stack cap | none | `maxDepth = 30` by default; rejected pushes return `false` |
| `replacePath` | did not clear modals in 1.0.x | clears sheet + cover |
| Modal types | one `ScreenView` type | independent `Sheet` and `Cover` types |
| macOS full screen cover | manual | presented as a sheet |
| Sheet while a cover is up | allowed (SwiftUI cannot show both) | `present(sheet:)` rejected, returns `false` (and vice versa) |

## Breaking changes in 2.0 (even if you stay on v1 APIs)

- `swift-tools-version: 6.0` — requires Xcode 16+.
- Minimum platforms raised to iOS 17 / macOS 14 / tvOS 17 / watchOS 10 / visionOS 1 (needed for `@Observable`).
- Public `Collection.subscript(safe:)` and `Array.removeLastSafe()` removed. Use `indices.contains(i) ? c[i] : nil` and `popLast()`.

## Using v2 without migrating everything

v1 API is still exported. You can, for example, keep `BaseNavigationStack` for a legacy feature while new features use `NavigationRouter`. Do not mount both on the same stack — each owns a different `NavigationStack`.

## Checklist

- [ ] Routes are `Hashable & Sendable` value types.
- [ ] `Sheet`/`Cover` are `Identifiable & Hashable & Sendable`.
- [ ] Router created with `@State`, not in `body`.
- [ ] All `pushToView`/`popBack`/… call sites renamed.
- [ ] `@Environment` type changed to the new router typealias.
- [ ] `maxDepth` reviewed for deep-flow features.
- [ ] Tests updated to `@MainActor` + direct `[Route]` assertions.
