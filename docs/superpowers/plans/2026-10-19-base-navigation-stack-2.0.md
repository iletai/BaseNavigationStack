# BaseNavigationStack 2.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nâng cấp toàn diện thư viện `BaseNavigationStack` lên phiên bản 2.0: Swift 6 Strict Concurrency, hợp nhất quản lý Stack/Sheet/Cover theo chuẩn `@Observable`, bảo vệ chống lỗi race condition/thao tác người dùng, bao phủ 100% test case lồng nhau (nested navigation) và thiết lập CI/CD GitHub Actions chuẩn Open-Source.

**Architecture:** Sử dụng Clean Architecture và mô hình Router hướng dữ liệu (Data-Driven Navigation) thuần SwiftUI không phụ thuộc UIKit hay bên thứ ba. Lớp router trung tâm `@MainActor @Observable public final class NavigationRouter<Route, Sheet, Cover>` quản lý state ba chiều (`path`, `sheet`, `cover`) độc lập, cung cấp các View modifier declarative giúp tích hợp O(1) vào bất kỳ SwiftUI View tree nào.

**Tech Stack:** Swift 6.0+, macOS 14+, iOS 17+, SwiftUI, Observation framework, Swift Testing / XCTest, GitHub Actions, SwiftLint.

**Spec:** Kế hoạch này hiện thực hóa toàn bộ các cải tiến từ quá trình audit codebase 2023, khắc phục bug logic `dismiss()`, loại bỏ ràng buộc đa associated type trong `BaseViewProtocol`, và thiết lập pipeline tự động hóa CI/CD cho Swift Package.

## Global Constraints

- **Dependency Limit:** Tuyệt đối 0 external dependencies (chỉ dùng standard library, Foundation, SwiftUI, Observation).
- **Platform Floors:** iOS 17.0+, macOS 14.0+.
- **Language Mode:** Swift 6 mode (`SWIFT_STRICT_CONCURRENCY = complete`, không để lọt bất kỳ warning hay error nào về actor isolation/Sendable).
- **Thread Safety:** Toàn bộ Router state mutations phải được cô lập trên `@MainActor`.
- **Backward Compatibility:** Cung cấp typealias và deprecation warnings thích hợp nếu cần hỗ trợ dự án cũ nâng cấp mượt mà.

## Review Focus

1. **Bug Dismiss khi path chỉ có 1 phần tử:** `dismiss()` phải pop được phần tử duy nhất trong `path` thay vì trigger dismiss root container.
2. **State Inconsistency khi Replace Path:** Khi thay thế `path`, toàn bộ modal active (`sheet`, `cover`) phải được tự động dọn dẹp để tránh modal đè lên flow mới.
3. **Double-Push / Rapid Tapping Race Condition:** Ngăn chặn việc append cùng một route liên tiếp trong cùng một chu kỳ runloop/animation khi người dùng tap nhanh nhiều lần.
4. **Nested Navigation Flow Lifecycle:** Khi một màn hình mở Sheet, và bên trong Sheet lại chứa một `NavigationRouter` con có stack riêng, việc dismiss từ bên trong hay bên ngoài phải giữ state cô lập và không rò rỉ bộ nhớ.
5. **Observation Direct Binding:** Không bọc thủ công `Binding(get:set:)`, tận dụng tối đa macro `@Bindable` của SwiftUI trên `@Observable`.

---

### Task 1: Nâng cấp Toolchain và Package Manifest (P0)

**Files:**
- Modify: `Package.swift`
- Modify: `Sources/BaseNavigationStack/Utils/Collection+Extension.swift`

**Interfaces:**
- Consumes: Standard Swift Package Manager manifest format
- Produces: Package hỗ trợ `.macOS(.v14)`, `.iOS(.v17)` với `swift-tools-version: 6.0`

- [ ] **Step 1: Viết test kiểm tra build trên môi trường macOS 14+**

Chạy: `swift build` trên repo gốc
Expected: FAIL do macOS 13 không tương thích `@Observable`.

- [ ] **Step 2: Cập nhật Package.swift lên Swift 6.0 và dọn dẹp extension thừa**

Cập nhật `Package.swift`:
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BaseNavigationStack",
    platforms: [
        .macOS(.v14), .iOS(.v17)
    ],
    products: [
        .library(
            name: "BaseNavigationStack",
            targets: ["BaseNavigationStack"]
        ),
    ],
    targets: [
        .target(
            name: "BaseNavigationStack",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "BaseNavigationStackTests",
            dependencies: ["BaseNavigationStack"]
        ),
    ]
)
```

Xóa helper thừa `removeAllSafe()` trong `Sources/BaseNavigationStack/Utils/Collection+Extension.swift` (vì `Array.removeAll()` vốn đã an toàn).

- [ ] **Step 3: Chạy swift build để xác nhận lỗi platform được giải quyết**

Run: `cd /Users/lequangtrongtai/orca/BaseNavigationStack && swift build`
Expected: Build thành công hoặc chỉ còn warnings về code v1 cũ.

- [ ] **Step 4: Commit thay đổi task 1**

```bash
git add Package.swift Sources/BaseNavigationStack/Utils/Collection+Extension.swift
git commit -m "build: upgrade package manifest to swift 6.0 and macos 14"
```

---

### Task 2: Core NavigationRouter 2.0 (Swift 6 & Observation) (P0)

**Files:**
- Modify: `Sources/BaseNavigationStack/BaseNavigationStack.swift`
- Modify: `Sources/BaseNavigationStack/Interface/BaseViewProtocol.swift`
- Modify: `Sources/BaseNavigationStack/StackObject/BaseNavigationStack+ViewObject.swift`

**Interfaces:**
- Consumes: `Observation`, `SwiftUI`
- Produces: 
  ```swift
  @MainActor @Observable public final class NavigationRouter<Route: Hashable & Sendable, Sheet: Identifiable & Hashable & Sendable, Cover: Identifiable & Hashable & Sendable>
  ```
  Hỗ trợ các method: `push(_:)`, `pop()`, `popToRoot()`, `present(sheet:)`, `present(cover:)`, `dismiss()`, `replacePath(_:)`.

- [ ] **Step 1: Viết failing unit tests cho Router state & dismiss logic**

Tạo file `Tests/BaseNavigationStackTests/NavigationRouterTests.swift` kiểm tra:
1. `push` và `pop` phần tử đúng thứ tự.
2. `dismiss` khi có đúng 1 phần tử trong path thì pop về mảng rỗng (Fix bug v1).
3. `dismiss` khi đang mở sheet thì đóng sheet, giữ nguyên stack.
4. `replacePath` tự động dismiss sheet và cover đang mở.

- [ ] **Step 2: Chạy test để xác nhận FAIL với code v1 hiện tại**

Run: `cd /Users/lequangtrongtai/orca/BaseNavigationStack && swift test --filter NavigationRouterTests`
Expected: FAIL

- [ ] **Step 3: Hiện thực hóa NavigationRouter 2.0**

Viết lại `Sources/BaseNavigationStack/BaseNavigationStack.swift` và các file liên quan:
- Áp dụng `@MainActor @Observable public final class BaseNavigationStack<ScreenView: BaseViewProtocol & Sendable>` (để backward compatible) và cung cấp class mới `NavigationRouter`.
- Sửa hàm `dismiss()`:
```swift
@MainActor
public func dismiss() {
    if state.presentingSheet != nil {
        state.presentingSheet = nil
    } else if state.presentingFullScreen != nil {
        state.presentingFullScreen = nil
    } else if !state.navigationPath.isEmpty {
        state.navigationPath.removeLast()
    } else {
        state.isPresented.wrappedValue = nil
    }
}
```
- Cơ chế debounce/guard chống double push:
```swift
@MainActor
public func pushToView(_ viewSpec: ScreenView) {
    // Tránh append liên tiếp cùng một target trong cùng 1 frame
    if state.navigationPath.last != viewSpec {
        state.navigationPath.append(viewSpec)
    }
}
```

- [ ] **Step 4: Chạy lại test suite để xác nhận PASS**

Run: `cd /Users/lequangtrongtai/orca/BaseNavigationStack && swift test`
Expected: PASS 100%

- [ ] **Step 5: Commit thay đổi task 2**

```bash
git add Sources/BaseNavigationStack/ Tests/BaseNavigationStackTests/
git commit -m "feat(core): implement NavigationRouter 2.0 with swift 6 strict concurrency"
```

---

### Task 3: Bộ kiểm thử nâng cao & Nested Navigation Flows (P0)

**Files:**
- Create: `Tests/BaseNavigationStackTests/NestedNavigationTests.swift`
- Create: `Tests/BaseNavigationStackTests/ConcurrencySafetyTests.swift`

**Interfaces:**
- Consumes: `NavigationRouter`, `BaseNavigationStack`
- Produces: Test cases bao phủ toàn bộ scenario:
  - Tab Router độc lập không ảnh hưởng lẫn nhau.
  - Modal chứa Stack con (Parent -> Sheet -> Child Stack Push -> Child Stack Pop -> Parent Dismiss).
  - Multi-threaded MainActor access isolation.

- [ ] **Step 1: Viết test suite Nested Navigation**

Hiện thực hóa `NestedNavigationTests.swift`:
- Mô phỏng App có MainRouter và SettingsRouter bên trong Sheet.
- Verify khi MainRouter mở Sheet Settings, SettingsRouter push màn hình con `subSettings`.
- Verify đóng MainRouter Sheet sẽ deinit và dọn dẹp an toàn SettingsRouter.

- [ ] **Step 2: Viết test suite Concurrency & Rapid Interaction**

Hiện thực hóa `ConcurrencySafetyTests.swift`:
- Test gọi rapid `pushToView` liên tiếp 5 lần với cùng destination xem có bị trùng lặp không mong muốn.
- Test `popBack()` khi stack rỗng không gây crash hay index out of bounds.

- [ ] **Step 3: Chạy toàn bộ test suite và xuất report coverage**

Run: `cd /Users/lequangtrongtai/orca/BaseNavigationStack && swift test --enable-code-coverage`
Expected: Mọi test case đều PASS với thời gian thực thi < 0.5s.

- [ ] **Step 4: Commit thay đổi task 3**

```bash
git add Tests/BaseNavigationStackTests/
git commit -m "test: add nested navigation and concurrency safety test suites"
```

---

### Task 4: Cập nhật Example App & Đồng bộ API Documentation (P1)

**Files:**
- Modify: `NavigationStackExample/NavigationStackExample/BaseDefineTarget/ViewNavigationTarget.swift`
- Modify: `NavigationStackExample/NavigationStackExample/ContentView.swift`
- Modify: `NavigationStackExample/NavigationStackExample/Utils/View+Extension.swift`
- Modify: `README.md`

**Interfaces:**
- Consumes: Public API `BaseNavigationStack` 2.0
- Produces: Ứng dụng mẫu hoàn chỉnh chạy được trên Simulator, README chính xác 100% kèm code snippets.

- [ ] **Step 1: Cập nhật code mẫu trong NavigationStackExample**

- Sửa `ViewNavigationTarget`: Bỏ closure trong `case updateProfile` để tránh lỗi non-Sendable và crash hash.
- Cập nhật `ContentView.swift`: Sử dụng `@Bindable` native của SwiftUI thay cho helper `binding(keyPath:)`.

- [ ] **Step 2: Cập nhật README.md**

- Sửa các badge bị gãy link (xóa badge `LFAlertController`).
- Thêm badge Swift 6.0, iOS 17.0+, macOS 14.0+, MIT License.
- Viết lại phần Usage đúng với API v2.0 (hướng dẫn dùng 1 generic type hoặc Router chuẩn).
- Bổ sung hướng dẫn giải quyết bài toán Nested Navigation & Deep Link.

- [ ] **Step 3: Chạy test và verify example**

Kiểm tra cú pháp và build không có warning.
Run: `swift test`

- [ ] **Step 4: Commit thay đổi task 4**

```bash
git add NavigationStackExample/ README.md
git commit -m "docs: update example app and align readme with 2.0 api"
```

---

### Task 5: Thiết lập CI/CD Chuẩn Open-Source (GitHub Actions & SwiftLint) (P0)

**Files:**
- Create: `.swiftlint.yml`
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/release.yml`
- Create: `.github/dependabot.yml`
- Create: `.github/PULL_REQUEST_TEMPLATE.md`

**Interfaces:**
- Consumes: GitHub Actions runner macOS 15, `swift test`, `xcodebuild`
- Produces: Tự động hóa kiểm thử PR/Push, tự động tạo Release khi có git tag.

- [ ] **Step 1: Tạo file cấu hình `.swiftlint.yml`**

Tạo `.swiftlint.yml` phù hợp Swift 6, tắt các rule quá khắt khe đối với view builder trong SwiftUI.

- [ ] **Step 2: Tạo workflow `.github/workflows/ci.yml`**

Tạo workflow CI gồm:
1. `lint`: Chạy swiftlint trên macOS runner.
2. `test-macos`: Chạy `swift test --enable-code-coverage` trên macOS 15.
3. `test-ios`: Chạy `xcodebuild test` trên iOS Simulator iPhone 16.

- [ ] **Step 3: Tạo workflow `.github/workflows/release.yml` và community files**

- `.github/workflows/release.yml`: Tự động build và phát hành GitHub Release kèm release notes khi có tag `v*`.
- Thêm PR template và dependabot.

- [ ] **Step 4: Kiểm tra cú pháp YAML của workflows**

Run: `git diff --check`
Expected: Không có lỗi thụt lề hay trailing whitespace trong file YAML.

- [ ] **Step 5: Commit thay đổi task 5**

```bash
git add .swiftlint.yml .github/
git commit -m "ci: add comprehensive github actions workflows and open source standards"
```
