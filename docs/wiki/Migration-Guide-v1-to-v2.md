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
| `dismiss()` | `dismiss()` (same ladder) |
| `navigationPath` binding | `router.path` (`$router.path` via `@Bindable`) |
| `presentingSheet`, `presentingFullScreen` | `router.sheet`, `router.cover` |
| `urlHandler` | `onOpenURL` / `handleOpenURL` equivalent mapping to `replacePath` |

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
| `dismiss()` on a 1-item stack | buggy/none in old builds | pops it |
| Duplicate push | debounced | debounced (same) |
| Stack cap | none | `maxDepth = 30` by default |
| `replacePath` | did not clear modals in old builds | clears sheet + cover |
| Modal types | one `ScreenView` type | independent `Sheet` and `Cover` types |
| macOS full screen cover | manual | compiled out |

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
