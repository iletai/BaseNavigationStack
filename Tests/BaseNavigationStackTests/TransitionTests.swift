import XCTest
import SwiftUI
@testable import BaseNavigationStack

@MainActor
final class TransitionTests: XCTestCase {
    func testZoomPushRecordsSourceAndPlainPushClearsIt() {
        let router = NavigationRouter<TestRoute, TestSheet, TestCover>()
        XCTAssertTrue(router.push(.detail(id: 1), zoomFrom: "card-1"))
        XCTAssertEqual(router.zoomSources[.detail(id: 1)], AnyHashable("card-1"))
        XCTAssertEqual(router.path, [.detail(id: 1)])

        router.pop()
        router.push(.detail(id: 1))
        XCTAssertNil(router.zoomSources[.detail(id: 1)])
    }

    func testRejectedZoomPushRecordsNothing() {
        let router = NavigationRouter<TestRoute, TestSheet, TestCover>(maxDepth: 1)
        router.push(.home)
        XCTAssertFalse(router.push(.profile, zoomFrom: 1))
        XCTAssertNil(router.zoomSources[.profile])
    }

    func testSheetPresentableExposesOptions() {
        struct S: SheetPresentable { var sheetOptions: SheetOptions { SheetOptions(detents: [.medium, .large]) } }
        let any: Any = S()
        XCTAssertEqual((any as? SheetPresentable)?.sheetOptions.detents, [.medium, .large])
    }
}
