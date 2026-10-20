# BaseNavigationStack 2.0

Modern, type-safe, data-driven navigation controller for SwiftUI (iOS 17+ & macOS 14+).

[![Swift Version](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017.0+%20%7C%20macOS%2014.0+-blue.svg)](https://developer.apple.com)
[![CI](https://github.com/iletai/BaseNavigationStack/actions/workflows/ci.yml/badge.svg)](https://github.com/iletai/BaseNavigationStack/actions)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

`BaseNavigationStack` simplifies navigation in SwiftUI by centralizing Stack pushes, Sheet modals, and FullScreenCover transitions under a single `@MainActor @Observable` state manager with **zero external dependencies**.

---

## Features

- **Swift 6 Strict Concurrency**: Fully isolated on `@MainActor` with Sendable checks enabled.
- **Unified Control**: Manage `path`, `sheet`, and `cover` from a single router without fragmented `@State` variables.
- **Race Condition Guard**: Automatic debounce for rapid taps prevents duplicated pushes.
- **Testable**: Pure Swift arrays (`[Route]`) allow inspecting the full navigation stack in unit tests with zero UI test overhead.
- **Nested Navigation Ready**: Support isolated routers per Tab and independent sub-routers inside Sheet modals.

---

## Installation

Add `BaseNavigationStack` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/iletai/BaseNavigationStack.git", from: "2.0.0")
],
targets: [
    .target(name: "YourTarget", dependencies: ["BaseNavigationStack"])
]
```

---

## Usage (Modern 2.0 API)

### 1. Define Routes

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
```

### 2. Setup Container View

```swift
import SwiftUI
import BaseNavigationStack

typealias AppRouter = NavigationRouter<AppRoute, AppSheet, AppCover>

struct RootContentView: View {
    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .detail(let id):
                        Text("Detail \(id)")
                    case .profile:
                        Text("User Profile")
                    }
                }
                .sheet(item: $router.sheet) { sheet in
                    Text("Sheet: \(sheet.id)")
                }
                .fullScreenCover(item: $router.cover) { cover in
                    Text("Cover: \(cover.id)")
                }
        }
        .environment(router)
    }
}
```

### 3. Navigate Programmatically

```swift
struct HomeView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Button("Push Detail") {
                router.push(.detail(id: 42))
            }
            Button("Present Sheet") {
                router.present(sheet: AppSheet(id: "login"))
            }
            Button("Pop Back") {
                router.pop()
            }
            Button("Pop to Root") {
                router.popToRoot()
            }
        }
    }
}
```

---

## Backward Compatibility (v1.x)

If upgrading from v1.x, `BaseNavigationStack<ScreenView>` remains supported with all logic bugs resolved:
- `dismiss()` now correctly pops single-screen stacks.
- `replaceNavigationStack(path:)` cleanly resets active modals.
- Full compatibility with SwiftUI `@Bindable`.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
