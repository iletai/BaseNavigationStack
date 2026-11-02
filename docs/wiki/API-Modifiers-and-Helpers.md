# API — Modifiers & Helpers

## `.navigationRouter(...)` View modifier

Attaches a `NavigationRouter`'s destinations and modals to the root content of a `NavigationStack` you build yourself, instead of using `BaseNavigationContainer`. It does **not** bind `path`: you must pass `$router.path` to `NavigationStack(path:)`.

### Full form

```swift
public extension View {
    @MainActor
    func navigationRouter<
        Route: Hashable & Sendable,
        Sheet: Identifiable & Hashable & Sendable,
        Cover: Identifiable & Hashable & Sendable,
        Destination: View,
        SheetContent: View,
        CoverContent: View
    >(
        _ router: NavigationRouter<Route, Sheet, Cover>,
        @ViewBuilder destination: @escaping (Route) -> Destination,
        @ViewBuilder sheet: @escaping (Sheet) -> SheetContent,
        @ViewBuilder cover: @escaping (Cover) -> CoverContent
    ) -> some View
}
```

Attaches, in order: `.navigationDestination(for:)`, `.sheet(item:)`, `.fullScreenCover(item:)` (a second `.sheet` on macOS), and `.environment(router)`. The router is also injected into every pushed destination: pushed screens take their environment from the `NavigationStack`, not from the view that declares `navigationDestination`, so without this they could not read `@Environment(AppRouter.self)`. Sheets and covers inherit it from the presenting view.

Apply it to the content **inside** the stack — `navigationDestination` must be declared within the `NavigationStack`, not on the stack itself.

```swift
struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationRouter(
                    router,
                    destination: { route in
                        switch route {
                        case .detail(let id): DetailView(id: id)
                        case .profile: ProfileView()
                        }
                    },
                    sheet: { sheet in
                        SheetView(sheet: sheet)
                    },
                    cover: { cover in
                        CoverView(cover: cover)
                    }
                )
        }
    }
}
```

### Stack-only overload

```swift
func navigationRouter<Route, Sheet, Cover, Destination: View>(
    _ router: NavigationRouter<Route, Sheet, Cover>,
    @ViewBuilder destination: @escaping (Route) -> Destination
) -> some View
```

Passes `EmptyView` for sheet and cover internally. On macOS the cover is presented as a sheet (same behavior as the container).

## `BaseViewProtocol`

v1 contract: a screen model that declares its own destinations.

```swift
public protocol BaseViewProtocol: Identifiable, Hashable, Sendable {
    associatedtype PresentSheetScreenView: View
    associatedtype DestinationView: View
    associatedtype PresentFullScreenView: View

    @MainActor @ViewBuilder func withNavigationDestination() -> DestinationView
    @MainActor @ViewBuilder func withSheetDestination() -> PresentSheetScreenView
    @MainActor @ViewBuilder func withFullScreenDestination() -> PresentFullScreenView
}
```

Example (a v1-style screen model; the demo app now uses v2 only):

```swift
enum ViewNavigationTarget: BaseViewProtocol {
    case splash
    case list
    case policy(URL)

    var id: String { /* stable identity */ }

    @MainActor func withNavigationDestination() -> some View {
        switch self {
        case .policy: PolicyView()
        case .list: ListView()
        case .splash: SplashView()
        }
    }

    @MainActor func withSheetDestination() -> some View { /* ... */ }
    @MainActor func withFullScreenDestination() -> some View { /* ... */ }
}
```

New code should prefer v2 routes (`Hashable & Sendable` enum + `destination:` closures) — views are mapped once in the container instead of on every model case. See [[Migration-Guide-v1-to-v2]].

## Legacy v1: `BaseNavigationStack<ScreenView>`

```swift
@MainActor @Observable
public final class BaseNavigationStack<ScreenView>
    where ScreenView: BaseViewProtocol
```

Kept for backward compatibility. Public surface:

| Member | Behavior |
|---|---|
| `init(isPresented: Binding<ScreenView?> = .constant(nil))` | Root binding for modal-presentation ownership. |
| `pushToView(_:)` | Append with duplicate-top debounce (no `maxDepth` cap in v1). |
| `popBack()` | Pops the top screen; no-op on empty. |
| `navigateToRoot()` | Clear path + sheet + cover. |
| `replaceNavigationStack(path:)` | Clear modals, replace path. |
| `presentSheet(_:)` / `presentFullScreen(_:)` | Set modal state. |
| `dismiss()` | sheet → cover → pop → `isPresented = nil` ladder. With the default `.constant(nil)` binding the last step is a no-op. |
| `urlHandler` | `(@MainActor (URL) -> OpenURLAction.Result)?` hook; `handleOpenURL(url:)` invokes it, defaults `.systemAction`. Stored strongly — capture owners with `[weak ...]`. |
| `navigationPath` / `presentingSheet` / `presentingFullScreen` / `isPresented` | `Binding` accessors. |

```swift
typealias BaseNavigation = BaseNavigationStack<ViewNavigationTarget>

let nav = BaseNavigation()
nav.pushToView(.list)
nav.popBack()
nav.dismiss()
```

v1 fixes shipped in 2.0: `dismiss()` now pops single-screen stacks; `replaceNavigationStack(path:)` resets active modals.
