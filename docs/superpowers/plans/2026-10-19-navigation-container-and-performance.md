# Navigation Container, Ergonomics & Performance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hiện thực hóa `BaseNavigationContainer` và ViewModifier declarative `.navigationRouter(...)`, tích hợp Stack Depth Guard giới hạn độ sâu stack chống memory bloating/warnings, hỗ trợ Async navigation action an toàn qua Actor boundaries, và cập nhật toàn bộ UI Showcase tương tác hoàn chỉnh.

**Architecture:** Sử dụng SwiftUI View composition thuần túy, đóng gói `NavigationStack`, `navigationDestination`, `.sheet`, `.fullScreenCover` vào một container duy nhất có generic constraints `Hashable & Identifiable & Sendable`. Quản lý state qua observation field-level tracking giúp triệt tiêu re-renders ngoài ý muốn.

**Tech Stack:** Swift 6.0, iOS 17.0+, macOS 14.0+, SwiftUI, Observation, XCTest / Swift Testing.

**Spec:** `docs/superpowers/specs/2026-10-19-navigation-container-and-performance-design.md`

## Global Constraints

- **Zero External Dependencies:** Chỉ dùng framework có sẵn của Apple.
- **Strict Concurrency Compliant:** `@MainActor` cô lập UI, `nonisolated` bridge cho background tasks.
- **Performance:** Thao tác kiểm tra độ sâu stack và deduplication chạy trong O(1).

## Review Focus

1. **Stack Overflow / Max Depth:** Nếu đẩy liên tục vượt quá `maxDepth` (mặc định 30), router phải reject hoặc log warning an toàn thay vì làm đầy heap memory.
2. **Actor Hopping Safety:** `router.send { $0.push(...) }` phải thực thi đúng trên `@MainActor` kể cả khi gọi từ một background detached task.
3. **Observation Granularity:** View chỉ lắng nghe Sheet không được re-render khi Stack path thay đổi.

---

### Task 1: Bổ sung Stack Depth Guard & Async Navigation Helper vào Router Core

**Files:**
- Modify: `Sources/BaseNavigationStack/NavigationRouter.swift`
- Test: `Tests/BaseNavigationStackTests/PerformanceAndAsyncTests.swift`

**Interfaces:**
- Consumes: `NavigationRouter`
- Produces: 
  - `public var maxDepth: Int = 30`
  - `public func push(_ route: Route)` có kiểm tra `path.count < maxDepth`
  - `nonisolated public func send(_ action: @escaping @MainActor (NavigationRouter) -> Void)`

- [ ] **Step 1: Viết test cho Stack Depth Guard và Async send**

Tạo `Tests/BaseNavigationStackTests/PerformanceAndAsyncTests.swift`:
- Test push 35 màn hình khi `maxDepth = 30` -> Verify stack dừng ở 30.
- Test gọi `send` từ `Task.detached` -> Verify route được đẩy vào stack trên main actor.

- [ ] **Step 2: Hiện thực hóa thay đổi trong NavigationRouter.swift**

Thêm `maxDepth` và `send` method vào `NavigationRouter.swift`.

- [ ] **Step 3: Chạy test kiểm chứng**

Run: `swift test --filter PerformanceAndAsyncTests`
Expected: PASS

- [ ] **Step 4: Commit task 1**

```bash
git add Sources/BaseNavigationStack/NavigationRouter.swift Tests/BaseNavigationStackTests/PerformanceAndAsyncTests.swift
git commit -m "feat(router): add stack depth guard and async send helper"
```

---

### Task 2: Hiện thực hóa BaseNavigationContainer & ViewModifier Declarative

**Files:**
- Create: `Sources/BaseNavigationStack/Views/BaseNavigationContainer.swift`
- Create: `Sources/BaseNavigationStack/Modifiers/NavigationRouterModifier.swift`
- Test: `Tests/BaseNavigationStackTests/ContainerViewTests.swift`

**Interfaces:**
- Produces:
  ```swift
  public struct BaseNavigationContainer<Route, Sheet, Cover, Content, Destination, SheetContent, CoverContent>: View
  ```
  ```swift
  extension View {
      public func navigationRouter<Route, Sheet, Cover>(...) -> some View
  }
  ```

- [ ] **Step 1: Tạo BaseNavigationContainer.swift**

Tạo component bọc `NavigationStack(path: $router.path)` kèm các destination modifiers.

- [ ] **Step 2: Tạo NavigationRouterModifier.swift**

Tạo extension modifier hỗ trợ declarative style.

- [ ] **Step 3: Viết test kiểm tra build và render của container**

Tạo `ContainerViewTests.swift` verify container khởi tạo thành công trên môi trường test.

- [ ] **Step 4: Chạy swift test**

Run: `swift test`
Expected: PASS 100%

- [ ] **Step 5: Commit task 2**

```bash
git add Sources/BaseNavigationStack/ Views/ Modifiers/ Tests/
git commit -m "feat(ui): add BaseNavigationContainer and declarative view modifiers"
```

---

### Task 3: Cập nhật Interactive Showcase Demo trong NavigationStackExample

**Files:**
- Modify: `NavigationStackExample/NavigationStackExample/ContentView.swift`
- Modify: `NavigationStackExample/NavigationStackExample/View/ListView.swift`
- Modify: `NavigationStackExample/NavigationStackExample/View/BaseView.swift`

**Interfaces:**
- Consumes: `BaseNavigationContainer`, `NavigationRouter`
- Produces: 3 Tab tương tác sinh động: Stack Trail, Nested Modals, Async & Stress Test.

- [ ] **Step 1: Viết lại ContentView.swift thành 3 Tab Showcase**

Hiện thực hóa giao diện TabView gồm 3 flows:
1. "Stack Explorer": Push/Pop, hiển thị visual trail số lượng view hiện tại.
2. "Nested Flow": Demo Sheet chứa child router độc lập.
3. "Async & Stress": Nút bấm gọi delay 1s và nút bấm 10 lần liên tục verify debounce.

- [ ] **Step 2: Chạy swift build và swiftlint**

Run: `swift build && swiftlint --strict --quiet`
Expected: Exit code 0, không có warning.

- [ ] **Step 3: Commit task 3**

```bash
git add NavigationStackExample/
git commit -m "feat(demo): build comprehensive 3-tab interactive showcase"
```
