# API — Modifiers & Helpers

## `.navigationRouter(...)` View modifier

Binds a `NavigationRouter` to an existing `NavigationStack` (or any view hierarchy) instead of using `BaseNavigationContainer`. Use it when you already build the `NavigationStack` yourself.

### Full form

```swift
public extension View {
    @MainActor @ViewBuilder
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

Attaches, in order: `.navigationDestination(for:)`, `.sheet(item:)`, `.fullScreenCover(item:)` (iOS/tvOS/watchOS/visionOS only), and `.environment(router)`.

```swift
struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
        }
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
```

### Stack-only overload

```swift
func navigationRouter<Route, Sheet, Cover, Destination: View>(
    _ router: NavigationRouter<Route, Sheet, Cover>,
    @ViewBuilder destination: @escaping (Route) -> Destination
) -> some View
```

Passes `EmptyView` for sheet and cover internally. On macOS the `fullScreenCover` branch is compiled out (same `#if` as the container).

## Collection helpers

`Sources/BaseNavigationStack/Utils/Collection+Extension.swift`:

```swift
extension Collection {
    /// Returns nil instead of trapping when out of bounds.
    public subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Array {
    /// removeLast() that is a no-op on empty arrays.
    public mutating func removeLastSafe() {
        guard !isEmpty else { return }
        removeLast()
    }
}
```

```swift
let stack = ["a", "b"]
let first = stack[safe: 5]   // nil, no crash
let mid = stack[safe: 0]     // Optional("a")

var path = [Route]()
path.removeLastSafe()        // no crash on empty path
```

These are public and used by the v1 `BaseNavigationStack` compatibility layer.

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

Example (from the demo app):

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
public final class BaseNavigationStack<ScreenView>: @unchecked Sendable
    where ScreenView: BaseViewProtocol
```

Kept for backward compatibility. Public surface:

| Member | Behavior |
|---|---|
| `init(isPresented: Binding<ScreenView?> = .constant(nil))` | Root binding for modal-presentation ownership. |
| `pushToView(_:)` | Append with duplicate-top debounce (no `maxDepth` cap in v1). |
| `popBack()` | `removeLastSafe()` — safe on empty. |
| `navigateToRoot()` | Clear path + sheet + cover. |
| `replaceNavigationStack(path:)` | Clear modals, replace path. |
| `presentSheet(_:)` / `presentFullScreen(_:)` | Set modal state. |
| `dismiss()` | sheet → cover → pop → `isPresented = nil` ladder. |
| `urlHandler` | `(@MainActor (URL) -> OpenURLAction.Result)?` hook; `handleOpenURL(url:)` invokes it, defaults `.systemAction`. |
| `navigationPath` / `presentingSheet` / `presentingFullScreen` / `isPresented` | `Binding` accessors. |

```swift
typealias BaseNavigation = BaseNavigationStack<ViewNavigationTarget>

let nav = BaseNavigation()
nav.pushToView(.list)
nav.popBack()
nav.dismiss()
```

v1 fixes shipped in 2.0: `dismiss()` now pops single-screen stacks; `replaceNavigationStack(path:)` resets active modals.
