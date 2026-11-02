# Nested & Tab Navigation

One router = one stack. Tabs and modals each get their own router instance; parent never sees child state.

## Independent routers per Tab

Each tab owns a router with `@State` in the tab host. Per-tab routes can even be different `Route` enums:

```swift
enum HomeRoute: Hashable, Sendable {
    case feed, post(id: Int)
}
enum SettingsRoute: Hashable, Sendable {
    case account, notifications
}

struct NoModal: Identifiable, Hashable, Sendable { let id = UUID() }

typealias HomeRouter = NavigationRouter<HomeRoute, NoModal, NoModal>
typealias SettingsRouter = NavigationRouter<SettingsRoute, NoModal, NoModal>

struct RootTabView: View {
    @State private var homeRouter = HomeRouter()
    @State private var settingsRouter = SettingsRouter()
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            BaseNavigationContainer(
                router: homeRouter,
                content: { FeedView() },
                destination: { route in
                    switch route {
                    case .feed: Text("Feed")
                    case .post(let id): PostView(id: id)
                    }
                }
            )
            .tabItem { Label("Home", systemImage: "house") }
            .tag(0)

            BaseNavigationContainer(
                router: settingsRouter,
                content: { SettingsView() },
                destination: { route in
                    switch route {
                    case .account: AccountView()
                    case .notifications: NotificationsView()
                    }
                }
            )
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(1)
        }
    }
}
```

Switching tabs does not reset stacks — `@State` keeps both alive in the host view. `popToRoot()` on one router never touches the other.

## Sheet with its own NavigationStack

A modal can host a fully isolated sub-stack. The child router lives inside the sheet view; the parent only knows "sheet is open":

```swift
// Parent router types
struct DemoSheet: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
}
struct DemoCover: Identifiable, Hashable, Sendable { let id: String }
enum DemoRoute: Hashable, Sendable { case detail(id: Int) }
typealias DemoRouter = NavigationRouter<DemoRoute, DemoSheet, DemoCover>

// Child router types
enum SubModalRoute: Hashable, Sendable {
    case subDetail
}

typealias SubRouter = NavigationRouter<SubModalRoute, DemoSheet, DemoCover>

struct NestedSheetContainerView: View {
    let sheet: DemoSheet
    @State private var subRouter = SubRouter()
    @Environment(DemoRouter.self) private var parentRouter   // for dismissing the sheet itself

    var body: some View {
        BaseNavigationContainer(
            router: subRouter,
            content: {
                VStack {
                    Text(sheet.title)
                    Button("Push Child Screen") { subRouter.push(.subDetail) }
                    Button("Dismiss Entire Sheet") { parentRouter.dismiss() }
                }
            },
            destination: { route in
                switch route {
                case .subDetail:
                    Button("Pop Child") { subRouter.pop() }
                }
            }
        )
    }
}
```

Rules of thumb:

- **Push/pop inside the modal** → child `subRouter`.
- **Close the modal** → parent `parentRouter.dismiss()`.
- Parent stack is untouched while the child stack grows — `dismissModals()` on the parent closes the sheet and discards child state.
- Child routes must not reference parent routes; keep enums separate.
- If the child router has the **same type** as the parent, `@Environment(ParentRouter.self)` inside the child container resolves to the child. Read the parent router outside the child container (as above), or give the child its own route types.
- A presented cover blocks `present(sheet:)` on the same router (it returns `false`). To show a sheet from inside a cover, give the cover its own router.

## Common pitfalls

1. **Creating the router inside `body`** — `let r = AppRouter()` re-instantiates every render, stack resets. Always `@State private var router = AppRouter()`.
2. **Sharing one router across tabs** — `popToRoot` in tab A nukes tab B. One router per stack.
3. **Presenting a cover on macOS** — presented as a sheet, since macOS has no full screen cover; see [[API-BaseNavigationContainer]].
4. **Nested `NavigationStack` on iOS 17** — legal inside `.sheet`, but never nest two stacks in the *same* column; give each its own modal boundary.
