import XCTest
import SwiftUI
@testable import BaseNavigationStack

enum AsyncRoute: Hashable, Sendable {
    case step(Int)
}

struct EmptyAsyncSheet: Identifiable, Hashable, Sendable {
    let id: String
}

@MainActor
final class PerformanceAndAsyncTests: XCTestCase {

    func testStackMaxDepthGuard() {
        let router = NavigationRouter<AsyncRoute, EmptyAsyncSheet, EmptyAsyncSheet>(maxDepth: 5)

        for stepIndex in 1...5 {
            XCTAssertTrue(router.push(.step(stepIndex)))
        }
        XCTAssertFalse(router.push(.step(6)), "push at maxDepth must report rejection")

        XCTAssertEqual(router.path.count, 5, "Stack must strictly not exceed maxDepth (5)")
        XCTAssertEqual(router.path.last, .step(5))

        // Replace path must also respect maxDepth
        let overflowList = (1...20).map { AsyncRoute.step($0) }
        XCTAssertFalse(router.replacePath(overflowList), "truncation must be reported")
        XCTAssertEqual(router.path.count, 5, "replacePath must clamp to maxDepth")
    }

    func testAsyncSendFromBackgroundThread() async {
        let router = NavigationRouter<AsyncRoute, EmptyAsyncSheet, EmptyAsyncSheet>()

        // Dispatch action from detached background Task and await the main-actor mutation itself
        let mutation = await Task.detached {
            router.send { targetRouter in
                targetRouter.push(.step(100))
            }
        }.value
        await mutation.value

        XCTAssertEqual(router.path, [.step(100)], "send() should safely mutate router on MainActor from background task")
    }

    func testMaxDepthClampedOnAssignment() {
        let router = NavigationRouter<AsyncRoute, EmptyAsyncSheet, EmptyAsyncSheet>(maxDepth: 0)
        XCTAssertEqual(router.maxDepth, 1)

        router.maxDepth = -1
        XCTAssertEqual(router.maxDepth, 1)
        // Previously crashed with prefix(-1)
        XCTAssertFalse(router.replacePath([.step(1), .step(2)]))
        XCTAssertEqual(router.path, [.step(1)])
    }

    func testInitialPathClampedToMaxDepth() {
        let router = NavigationRouter<AsyncRoute, EmptyAsyncSheet, EmptyAsyncSheet>(
            initialPath: (1...5).map { AsyncRoute.step($0) },
            maxDepth: 3
        )
        XCTAssertEqual(router.path, [.step(1), .step(2), .step(3)])
    }

}
