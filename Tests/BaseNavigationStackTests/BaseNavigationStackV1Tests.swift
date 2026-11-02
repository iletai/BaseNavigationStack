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

    func testLegacyPopAndRoot() {
        let stack = BaseNavigationStack<LegacyTarget>()
        stack.pushToView(.first)
        stack.pushToView(.first)
        stack.pushToView(.second)
        XCTAssertEqual(stack.navigationPath.wrappedValue, [.first, .second])

        stack.popBack()
        XCTAssertEqual(stack.navigationPath.wrappedValue, [.first])

        stack.presentSheet(.second)
        stack.navigateToRoot()
        XCTAssertTrue(stack.navigationPath.wrappedValue.isEmpty)
        XCTAssertNil(stack.presentingSheet.wrappedValue)

        // Empty stack pop is a no-op
        stack.popBack()
        XCTAssertTrue(stack.navigationPath.wrappedValue.isEmpty)
    }

    func testLegacyDismissFallsBackToParentBinding() {
        var parentPresented: LegacyTarget? = .first
        let binding = Binding(get: { parentPresented }, set: { parentPresented = $0 })
        let stack = BaseNavigationStack<LegacyTarget>(isPresented: binding)

        stack.dismiss()
        XCTAssertNil(parentPresented, "Dismiss on empty stack must clear parent presentation")
    }

    func testLegacyURLHandler() {
        let stack = BaseNavigationStack<LegacyTarget>()
        let url = URL(string: "myapp://x")!
        var received: URL?
        stack.urlHandler = { url in
            received = url
            return .handled
        }
        _ = stack.handleOpenURL(url: url)
        XCTAssertEqual(received, url)
    }
}
