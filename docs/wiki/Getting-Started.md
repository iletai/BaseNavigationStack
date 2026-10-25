# Getting Started

## 1. Install (SPM)

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/iletai/BaseNavigationStack.git", from: "2.0.0")
],
targets: [
    .target(name: "YourTarget", dependencies: ["BaseNavigationStack"])
]
```

Or in Xcode: **File → Add Package Dependencies…** → `https://github.com/iletai/BaseNavigationStack.git`.

Platforms: iOS 17.0+, macOS 14.0+. Swift tools 6.0.

## 2. Define your Route enum

```swift
import Foundation

enum AppRoute: Hashable, Sendable {
    case detail(id: Int)
    case profile
}

struct AppSheet: Identifiable, Hashable, Sendable {
    let id: String
}

struct AppCover: Identifiable, Hashable, Sendable {
    let id: String
}

typealias AppRouter = NavigationRouter<AppRoute, AppSheet, AppCover>
```

`Route` needs `Hashable & Sendable`. Sheets and covers additionally need `Identifiable` (SwiftUI `.sheet(item:)` requirement).

## 3. Mount the container

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
                    Text("Detail \(id)")
                case .profile:
                    Text("User Profile")
                }
            },
            sheet: { sheet in
                Text("Sheet: \(sheet.id)")
            },
            cover: { cover in
                Text("Cover: \(cover.id)")
            }
        )
    }
}
```

No sheet/cover? Use the default initializer (see [[API-BaseNavigationContainer]]):

```swift
BaseNavigationContainer(
    router: router,
    content: { HomeView() },
    destination: { route in /* ... */ }
)
```

## 4. Navigate from any child view

The container injects the router via `.environment(router)`, so descendants read it with `@Environment`:

```swift
struct HomeView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Button("Push Detail") { router.push(.detail(id: 42)) }
            Button("Present Sheet") { router.present(sheet: AppSheet(id: "login")) }
            Button("Pop") { router.pop() }
            Button("Pop to Root") { router.popToRoot() }
        }
    }
}
```

Full API: [[API-NavigationRouter]].
