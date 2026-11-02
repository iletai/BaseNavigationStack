import XCTest
import SwiftUI
@testable import BaseNavigationStack

enum TestRoute: Hashable, Sendable {
    case home
    case detail(id: Int)
    case profile
}

struct TestSheet: Identifiable, Hashable, Sendable {
    let id: String
}

struct TestCover: Identifiable, Hashable, Sendable {
    let id: String
}

@MainActor
final class NavigationRouterTests: XCTestCase {

    func testPushAndPop() {
        let router = NavigationRouter<TestRoute, TestSheet, TestCover>()
        XCTAssertTrue(router.path.isEmpty)

        router.push(.detail(id: 1))
        XCTAssertEqual(router.path, [.detail(id: 1)])

        router.push(.profile)
        XCTAssertEqual(router.path.count, 2)

        router.pop()
        XCTAssertEqual(router.path, [.detail(id: 1)])

        router.pop()
        XCTAssertTrue(router.path.isEmpty)

        // Pop on empty should be safe
        router.pop()
        XCTAssertTrue(router.path.isEmpty)
    }

    func testPopMultiple() {
        let router = NavigationRouter<TestRoute, TestSheet, TestCover>()
        router.push(.home)
        router.push(.detail(id: 1))
        router.push(.detail(id: 2))
        router.push(.profile)
        XCTAssertEqual(router.path.count, 4)

        router.pop(count: 2)
        XCTAssertEqual(router.path, [.home, .detail(id: 1)])

        // Popping more than available should empty the stack safely
        router.pop(count: 10)
        XCTAssertTrue(router.path.isEmpty)
    }

    func testDuplicatePushDebounce() {
        let router = NavigationRouter<TestRoute, TestSheet, TestCover>()
        XCTAssertTrue(router.push(.home))
        XCTAssertFalse(router.push(.home), "Repeated immediate push must report rejection")
        XCTAssertEqual(router.path.count, 1)

        router.push(.detail(id: 1))
        XCTAssertEqual(router.path.count, 2)
    }

    func testDismissLadder() {
        let router = NavigationRouter<TestRoute, TestSheet, TestCover>()
        router.push(.home)

        // Case 1: Stack only with 1 item - dismiss should pop it (v1 bug was: count > 1 required)
        router.dismiss()
        XCTAssertTrue(router.path.isEmpty, "Dismiss should pop the single item in stack")

        // Case 2: Sheet active - dismiss should close sheet and keep stack intact
        router.push(.home)
        router.present(sheet: TestSheet(id: "s1"))
        XCTAssertNotNil(router.sheet)
        router.dismiss()
        XCTAssertNil(router.sheet)
        XCTAssertEqual(router.path, [.home])

        // Case 3: Cover active - dismiss should close cover and keep stack intact
        router.present(cover: TestCover(id: "c1"))
        XCTAssertNotNil(router.cover)
        router.dismiss()
        XCTAssertNil(router.cover)
        XCTAssertEqual(router.path, [.home])
    }

    func testReplacePathClearsModals() {
        let router = NavigationRouter<TestRoute, TestSheet, TestCover>()
        router.push(.home)
        router.present(sheet: TestSheet(id: "s1"))

        XCTAssertTrue(router.replacePath([.detail(id: 99)]))
        XCTAssertNil(router.sheet)
        XCTAssertNil(router.cover)
        XCTAssertEqual(router.path, [.detail(id: 99)])
    }

    func testPopToRootClearsAll() {
        let router = NavigationRouter<TestRoute, TestSheet, TestCover>()
        router.push(.home)
        router.push(.detail(id: 1))
        router.present(sheet: TestSheet(id: "s1"))

        router.popToRoot()
        XCTAssertTrue(router.path.isEmpty)
        XCTAssertNil(router.sheet)
        XCTAssertNil(router.cover)
    }

    func testSheetAndCoverAreMutuallyExclusive() {
        let router = NavigationRouter<TestRoute, TestSheet, TestCover>()

        XCTAssertTrue(router.present(sheet: TestSheet(id: "s1")))
        XCTAssertFalse(router.present(cover: TestCover(id: "c1")))
        XCTAssertNil(router.cover)

        // Swapping one sheet for another is allowed
        XCTAssertTrue(router.present(sheet: TestSheet(id: "s2")))
        XCTAssertEqual(router.sheet?.id, "s2")

        router.dismiss()
        XCTAssertTrue(router.present(cover: TestCover(id: "c1")))
        XCTAssertFalse(router.present(sheet: TestSheet(id: "s3")))
        XCTAssertNil(router.sheet)
    }

    func testInitKeepsOnlyOneModal() {
        let router = NavigationRouter<TestRoute, TestSheet, TestCover>(
            initialSheet: TestSheet(id: "s1"),
            initialCover: TestCover(id: "c1")
        )
        XCTAssertNotNil(router.sheet)
        XCTAssertNil(router.cover)
    }

    func testPopNonPositiveCountIsNoOp() {
        let router = NavigationRouter<TestRoute, TestSheet, TestCover>(initialPath: [.home, .profile])
        router.pop(count: 0)
        router.pop(count: -3)
        XCTAssertEqual(router.path, [.home, .profile])
    }
}
