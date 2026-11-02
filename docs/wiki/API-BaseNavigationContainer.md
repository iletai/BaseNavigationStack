# API — BaseNavigationContainer

Declarative container that wires a `NavigationRouter` into a SwiftUI `NavigationStack`, destination mapping, sheet and full screen cover.

## Signature

```swift
public struct BaseNavigationContainer<
    Route: Hashable & Sendable,
    Sheet: Identifiable & Hashable & Sendable,
    Cover: Identifiable & Hashable & Sendable,
    Content: View,
    Destination: View,
    SheetContent: View,
    CoverContent: View
>: View
```

Generic parameters:

| Parameter | Role |
|---|---|
| `Route` | Destination type pushed onto `NavigationStack` |
| `Sheet` | Identifiable model driving `.sheet(item:)` |
| `Cover` | Identifiable model driving `.fullScreenCover(item:)` |
| `Content` | Root view inside the stack |
| `Destination` | View built from a `Route` |
| `SheetContent` | View built from a `Sheet` |
| `CoverContent` | View built from a `Cover` |

SwiftUI infers the five view generics from the closures — you only name the three model types on the router.

## Full initializer

```swift
public init(
    router: NavigationRouter<Route, Sheet, Cover>,
    @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder destination: @escaping (Route) -> Destination,
    @ViewBuilder sheet: @escaping (Sheet) -> SheetContent,
    @ViewBuilder cover: @escaping (Cover) -> CoverContent
)
```

```swift
@State private var router = AppRouter()

BaseNavigationContainer(
    router: router,
    content: { HomeView() },
    destination: { route in DestinationView(route: route) },
    sheet: { sheet in SheetView(sheet: sheet) },
    cover: { cover in CoverView(cover: cover) }
)
```

## Default initializer (no modals)

When `SheetContent == EmptyView` and `CoverContent == EmptyView`, this convenience initializer exists:

```swift
public init(
    router: NavigationRouter<Route, Sheet, Cover>,
    @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder destination: @escaping (Route) -> Destination
)
```

```swift
BaseNavigationContainer(
    router: router,
    content: { HomeView() },
    destination: { route in DestinationView(route: route) }
)
```

You still declare `Sheet`/`Cover` types on the router (partial application with `EmptyView` is not possible), but they are never presented. To avoid declaring dummy types, see the `navigationRouter(_:destination:)` modifier in [[API-Modifiers-and-Helpers]] — it also requires the three types, so the practical minimal setup is small empty `Identifiable` structs:

```swift
struct NoSheet: Identifiable, Hashable, Sendable { let id = UUID() }
struct NoCover: Identifiable, Hashable, Sendable { let id = UUID() }

typealias AppRouter = NavigationRouter<AppRoute, NoSheet, NoCover>
```

## Platform behavior

`fullScreenCover` does not exist on macOS. The container (and the `.navigationRouter` modifier it uses) presents the cover through a single internal helper:

```swift
NavigationStack(path: $router.path) {
    content()
        .navigationRouter(router, destination: destination, sheet: sheetContent, cover: coverContent)
}
.environment(router)

// inside .navigationRouter:
#if os(macOS)
sheet(item: $router.cover, content: coverContent)
#else
fullScreenCover(item: $router.cover, content: coverContent)
#endif
```

On macOS the `cover:` closure is shown as a sheet, so `present(cover:)` is always visible and `dismiss()` closes what the user sees.

## Behavior notes

- Router is stored as `@Bindable`, so `$router.path`, `$router.sheet`, `$router.cover` drive SwiftUI directly.
- `.environment(router)` is applied to the stack — every pushed destination, sheet, and cover can read it with `@Environment(AppRouter.self)`.
- Modals are attached **inside** the `NavigationStack`; a sheet presented from a pushed screen still closes when the router's `sheet` becomes `nil`.
- The container does not own the router. Create it with `@State` in the parent so it survives view re-creation.

## Complete example

```swift
struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        BaseNavigationContainer(
            router: router,
            content: { HomeView() },
            destination: { route in
                switch route {
                case .detail(let id): DetailView(id: id)
                case .profile: ProfileView()
                }
            },
            sheet: { sheet in
                SheetView(sheet: sheet)
                    .presentationDetents([.medium, .large])
            },
            cover: { cover in
                CoverView(cover: cover)
                    .ignoresSafeArea()
            }
        )
    }
}
```
