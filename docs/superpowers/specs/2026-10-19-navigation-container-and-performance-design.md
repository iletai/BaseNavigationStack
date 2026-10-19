# BaseNavigationStack 2.0: Container View, Async Ergonomics & Performance Spec

**Goal:** Cung cấp container component SwiftUI `BaseNavigationContainer` và ViewModifier declarative gọn nhẹ, hỗ trợ điều hướng bất đồng bộ (Async navigation / Actor safe), kiểm soát tối đa số lượng view trong stack tránh memory bloating/warnings, và tối ưu hiệu năng O(1) observation.

## 1. Kiến trúc thành phần

### 1.1. BaseNavigationContainer
Component SwiftUI đóng gói toàn bộ lifecycle điều hướng:
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
- Tự động quản lý `NavigationStack(path: $router.path)`.
- Gắn `.navigationDestination(for: Route.self)` ở cấp độ root container chuẩn Apple HIG.
- Quản lý `.sheet(item: $router.sheet)` và `.fullScreenCover(item: $router.cover)`.
- Tự động inject `.environment(router)` xuống cây view phân cấp.

### 1.2. ViewModifier Extension `.navigationRouter(...)`
Cung cấp giải pháp linh hoạt khi end-user đã có sẵn `NavigationStack`:
```swift
extension View {
    public func navigationRouter<Route, Sheet, Cover>(
        _ router: NavigationRouter<Route, Sheet, Cover>,
        @ViewBuilder destination: @escaping (Route) -> some View,
        @ViewBuilder sheet: @escaping (Sheet) -> some View = { _ in EmptyView() },
        @ViewBuilder cover: @escaping (Cover) -> some View = { _ in EmptyView() }
    ) -> some View
}
```

## 2. Kiểm soát hiệu năng & Tránh lỗi số lượng View trong Stack

1. **Stack Depth Guard (`maxDepth: Int`)**:
   - Khi độ sâu stack vượt quá ngưỡng (ví dụ: > 30 màn hình), router tự động cảnh báo qua logger hoặc giới hạn để tránh crash bộ nhớ và SwiftUI layout recursion warnings.
2. **O(1) Deduplication / Debounce**:
   - So sánh nhanh `path.last == route` (O(1)) để ngăn chặn việc người dùng double-tap tạo ra 2 màn hình giống hệt nhau liên tiếp.
3. **Observation Field-Level Tracking**:
   - Tách biệt `path`, `sheet`, `cover` trong `@Observable`. Chỉ các View tiêu thụ thuộc tính tương ứng mới được re-render khi state thay đổi.
4. **Actor-Safe Background Hopping**:
   - Bổ sung `nonisolated public func send(_ action: @escaping @MainActor (NavigationRouter) -> Void)` cho phép gọi điều hướng an toàn từ `Task.detached` hoặc background actor.

## 3. UI Showcase Demo

Xây dựng bộ demo tương tác 3 tabs trực quan trong `NavigationStackExample`:
- **Tab 1 - Core Stack**: Push/Pop, hiển thị visual stack trail, popToRoot.
- **Tab 2 - Nested Modals**: Mở Sheet chứa sub-router riêng, verify đóng độc lập.
- **Tab 3 - Async & Performance**: Giả lập API delay 1s -> navigate, stress-test nút bấm liên tục.
