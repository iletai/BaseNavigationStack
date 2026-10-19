import XCTest
import SwiftUI
@testable import BaseNavigationStack

enum HeavyRoute: Hashable, Sendable {
    case item(Int)
}

struct EmptySheet: Identifiable, Hashable, Sendable {
    let id: String
}

@MainActor
final class ConcurrencySafetyTests: XCTestCase {

    /// Scenario: User taps a button multiple times rapidly in the same frame/runloop.
    /// Deduplication prevents pushing duplicate consecutive screens.
    func testRapidTapDebounce() {
        let router = NavigationRouter<HeavyRoute, EmptySheet, EmptySheet>()

        // 10 rapid taps on the same item
        for _ in 0..<10 {
            router.push(.item(42))
        }

        XCTAssertEqual(router.path.count, 1, "Immediate consecutive identical pushes must be debounced to 1")
        XCTAssertEqual(router.path, [.item(42)])

        // Tapping a different item immediately goes through
        router.push(.item(43))
        XCTAssertEqual(router.path.count, 2)
    }

    /// Scenario: Calling pop or dismiss on an empty router should be a graceful no-op.
    func testSafeDismissOnEmptyStack() {
        let router = NavigationRouter<HeavyRoute, EmptySheet, EmptySheet>()

        XCTAssertTrue(router.path.isEmpty)
        router.pop()
        router.pop(count: 5)
        router.dismiss()
        router.dismissModals()
        router.popToRoot()

        XCTAssertTrue(router.path.isEmpty)
    }
}
