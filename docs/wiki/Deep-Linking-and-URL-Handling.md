# Deep Linking & URL Handling

Core idea: parse URL → `[Route]` → `replacePath(_:)`. The router is plain data, so deep linking is just constructing an array.

## 1. Define URL scheme / universal links

Info.plist (`CFBundleURLTypes`) for custom scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array><string>myapp</string></array>
    </dict>
</array>
```

For universal links, add the Associated Domains entitlement: `applinks:example.com`.

## 2. Map URL path to `[AppRoute]`

```swift
enum AppRoute: Hashable, Sendable {
    case home
    case detail(id: Int)
    case profile
}

struct AppDeepLink {
    static func routes(from url: URL) -> [AppRoute] {
        guard url.scheme == "myapp" || url.host == "example.com" else {
            return []
        }
        let parts = url.pathComponents.filter { $0 != "/" }
        switch parts.first {
        case "home":
            return [.home]
        case "detail":
            guard parts.count >= 2, let id = Int(parts[1]) else { return [.home] }
            return [.home, .detail(id: id)]
        case "profile":
            return [.home, .profile]
        default:
            return []
        }
    }
}
```

`myapp://detail/42` → `[.home, .detail(id: 42)]`.

## 3. Apply on launch and on open

```swift
@main
struct MyApp: App {
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView(router: router)
                .onOpenURL { url in
                    let routes = AppDeepLink.routes(from: url)
                    guard !routes.isEmpty else { return }
                    router.replacePath(routes)
                }
                .onAppear {
                    if let url = URL(string: "myapp://home") {
                        router.replacePath(AppDeepLink.routes(from: url))
                    }
                }
        }
    }
}
```

`replacePath` clears any active sheet/cover and truncates to `maxDepth` — the correct semantic for "jump to this destination".

Prefer **pushing incrementally** (`push` per segment) when intermediate screens must appear in the back stack history; both work — `replacePath` is all-or-nothing, repeated `push` builds the history (watch duplicate-top debounce when a segment repeats).

## 4. Redirect to a modal

```swift
static func apply(url: URL, router: AppRouter) {
    switch url.pathComponents.filter({ $0 != "/" }).first {
    case "paywall":
        router.present(sheet: AppSheet(id: "paywall"))
    default:
        router.replacePath(routes(from: url))
    }
}
```

## Legacy v1 `urlHandler`

v1 `BaseNavigationStack` exposes a handler hook:

```swift
typealias BaseNavigation = BaseNavigationStack<ViewNavigationTarget>

let nav = BaseNavigation()
nav.urlHandler = { url in
    nav.pushToView(.policy(url))
    return .handled
}

// Somewhere in the view:
.onOpenURL { _ = nav.handleOpenURL(url: $0) }
```

Return `.systemAction` (default) to let SwiftUI handle the URL normally, `.handled` to consume it.

## iOS scene phase / sceneDelegate delivery

If your app uses `Scene` with `WindowGroup`, `onOpenURL` covers both cold and warm launches. For UIKit-forward apps, forward `application(_:open:options:)` into the same `router.replacePath(AppDeepLink.routes(from: url))` call.
