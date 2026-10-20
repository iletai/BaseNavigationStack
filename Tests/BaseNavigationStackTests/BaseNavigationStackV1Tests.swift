import XCTest
import SwiftUI
@testable import BaseNavigationStack

enum LegacyTarget: BaseViewProtocol {
    case first
    case second
    var id: String { "\(self)" }

    @MainActor
    func withSheetDestination() -> some View { EmptyView() }
    @MainActor
    func withFullScreenDestination() -> some View { EmptyView() }
    @MainActor
    func withNavigationDestination() -> some View { EmptyView() }
}

@MainActor
final class BaseNavigationStackV1Tests: XCTestCase {
    func testLegacyDismissOnSingleScreen() {
        let stack = BaseNavigationStack<LegacyTarget>(isPresented: .constant(nil))
        stack.pushToView(.first)
        XCTAssertEqual(stack.navigationPath.wrappedValue.count, 1)

        // Verifying fix: previously required count > 1 to pop, now pops when count == 1
        stack.dismiss()
        XCTAssertEqual(stack.navigationPath.wrappedValue.count, 0)
    }

    func testLegacyReplaceClearsModals() {
        let stack = BaseNavigationStack<LegacyTarget>(isPresented: .constant(nil))
        stack.presentSheet(.first)
        stack.presentFullScreen(.first)
        XCTAssertNotNil(stack.presentingSheet.wrappedValue)
        XCTAssertNotNil(stack.presentingFullScreen.wrappedValue)

        stack.replaceNavigationStack(path: [.second])
        XCTAssertNil(stack.presentingSheet.wrappedValue)
        XCTAssertNil(stack.presentingFullScreen.wrappedValue)
        XCTAssertEqual(stack.navigationPath.wrappedValue, [.second])
    }
}
