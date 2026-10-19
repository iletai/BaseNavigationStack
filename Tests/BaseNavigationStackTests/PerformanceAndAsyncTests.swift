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

        for stepIndex in 1...10 {
            router.push(.step(stepIndex))
        }

        XCTAssertEqual(router.path.count, 5, "Stack must strictly not exceed maxDepth (5)")
        XCTAssertEqual(router.path.last, .step(5))

        // Replace path must also respect maxDepth
        let overflowList = (1...20).map { AsyncRoute.step($0) }
        router.replacePath(overflowList)
        XCTAssertEqual(router.path.count, 5, "replacePath must clamp to maxDepth")
    }

    func testAsyncSendFromBackgroundThread() async {
        let router = NavigationRouter<AsyncRoute, EmptyAsyncSheet, EmptyAsyncSheet>()

        // Dispatch action from detached background Task
        await Task.detached {
            // Perform simulated heavy work
            try? await Task.sleep(nanoseconds: 10_000_000)
            router.send { targetRouter in
                targetRouter.push(.step(100))
            }
        }.value

        // Allow runloop to process MainActor task
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(router.path, [.step(100)], "send() should safely mutate router on MainActor from background task")
    }
}
