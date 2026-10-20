import XCTest
import SwiftUI
@testable import BaseNavigationStack

// MARK: - Route Definitions for Multi-Level Nested Flow

enum AppTabRoute: Hashable, Sendable {
    case feed
    case settings
}

enum SettingsSubRoute: Hashable, Sendable {
    case general
    case security
    case advancedOptions
}

struct SettingsModal: Identifiable, Hashable, Sendable {
    let id: String
}

struct EmptyCover: Identifiable, Hashable, Sendable {
    let id: String
}

@MainActor
final class NestedNavigationTests: XCTestCase {

    /// Scenario: A screen in the main stack opens a Modal Sheet.
    /// The Modal Sheet contains its OWN child NavigationRouter with independent stack.
    /// Child stack navigates 2 levels deep, then dismisses back to modal root,
    /// then parent dismisses the entire modal cleanly.
    func testParentChildRouterLifecycle() {
        // 1. Parent Root Router
        let parentRouter = NavigationRouter<AppTabRoute, SettingsModal, EmptyCover>()
        parentRouter.push(.feed)
        XCTAssertEqual(parentRouter.path, [.feed])

        // 2. Parent presents Settings modal
        parentRouter.present(sheet: SettingsModal(id: "settings-sheet"))
        XCTAssertNotNil(parentRouter.sheet)

        // 3. Child Stack inside Settings modal
        let childRouter = NavigationRouter<SettingsSubRoute, EmptyCover, EmptyCover>()
        XCTAssertTrue(childRouter.path.isEmpty)

        childRouter.push(.general)
        childRouter.push(.security)
        childRouter.push(.advancedOptions)
        XCTAssertEqual(childRouter.path.count, 3)

        // 4. Child pops one level
        childRouter.dismiss()
        XCTAssertEqual(childRouter.path, [.general, .security])

        // 5. Child pops to root
        childRouter.popToRoot()
        XCTAssertTrue(childRouter.path.isEmpty)

        // 6. Parent dismisses modal sheet
        parentRouter.dismiss()
        XCTAssertNil(parentRouter.sheet)
        // Parent stack remains untouched
        XCTAssertEqual(parentRouter.path, [.feed])
    }

    /// Scenario: Two independent tabs have their own routers (e.g. Tab 1 vs Tab 2).
    /// Mutating Tab 1 router must not cause any side-effects on Tab 2 router.
    func testTabRoutersStateIsolation() {
        let tab1Router = NavigationRouter<AppTabRoute, SettingsModal, EmptyCover>()
        let tab2Router = NavigationRouter<SettingsSubRoute, SettingsModal, EmptyCover>()

        tab1Router.push(.feed)
        tab1Router.push(.settings)

        XCTAssertEqual(tab1Router.path.count, 2)
        XCTAssertTrue(tab2Router.path.isEmpty)

        tab2Router.push(.general)
        XCTAssertEqual(tab2Router.path.count, 1)

        tab1Router.popToRoot()
        XCTAssertTrue(tab1Router.path.isEmpty)
        // Tab 2 must stay intact
        XCTAssertEqual(tab2Router.path, [.general])
    }
}
