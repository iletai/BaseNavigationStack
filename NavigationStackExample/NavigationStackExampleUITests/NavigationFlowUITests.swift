//
//  NavigationFlowUITests.swift
//  NavigationStackExampleUITests
//
//  Drives the example app to verify the router against real SwiftUI rendering.
//  Every step attaches a screenshot to the test result bundle.
//

import XCTest

final class NavigationFlowUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    // MARK: - Normal cases

    @MainActor
    func testPushPopAndPopToRoot() {
        let app = launch()
        tap(app, "Push Next Step")
        assertVisible(app, "Step Screen #1")
        tap(app, "Push Step #2")
        assertVisible(app, "Step Screen #2")
        snapshot(app, "stack-depth-2")

        tap(app, "Pop Back")
        assertVisible(app, "Step Screen #1")
        tap(app, "Pop to Root")
        XCTAssertEqual(text(app, "depthLabel"), "Current Stack Depth: 0 / 30")
        snapshot(app, "stack-back-at-root")
    }

    @MainActor
    func testSheetHostsIndependentChildStack() {
        let app = launch()
        tap(app, "Present Modal Sheet")
        assertVisible(app, "Nested Flow Sheet")
        tap(app, "Push Child Stack Screen")
        assertVisible(app, "Child Stack Detail")
        snapshot(app, "sheet-child-pushed")

        tap(app, "Pop Child Screen")
        assertVisible(app, "Nested Flow Sheet")
        tap(app, "Dismiss Entire Sheet")
        XCTAssertTrue(app.staticTexts["depthLabel"].waitForExistence(timeout: 5))
        XCTAssertEqual(text(app, "depthLabel"), "Current Stack Depth: 0 / 30", "Parent stack must be untouched")
        snapshot(app, "sheet-dismissed")
    }

    @MainActor
    func testFullScreenCoverPresentsAndDismisses() {
        let app = launch()
        tap(app, "Present Full Screen Cover")
        assertVisible(app, "Full Screen Cover: cover-1")
        snapshot(app, "cover-presented")

        tap(app, "Dismiss Cover")
        XCTAssertTrue(app.staticTexts["depthLabel"].waitForExistence(timeout: 5))
        snapshot(app, "cover-dismissed")
    }

    @MainActor
    func testBackgroundSendPushesOnMainActor() {
        let app = launch()
        tap(app, "Async Lab")
        tap(app, "Simulate Background Async Push")
        assertVisible(app, "Loaded from Network Actor", timeout: 8)
        snapshot(app, "async-send-pushed")
    }

    @MainActor
    func testModifierRecipePropagatesRouterToPushedScreens() {
        let app = launch()
        tap(app, "Modifier")
        tap(app, "Push Via Modifier")
        XCTAssertTrue(app.staticTexts["modifierEnvDepth"].waitForExistence(timeout: 5),
                      "Pushed destination did not render (router missing from environment?)")
        XCTAssertEqual(text(app, "modifierEnvDepth"), "Env router depth: 1")

        tap(app, "Push Another Via Env")
        XCTAssertTrue(app.staticTexts["Env router depth: 2"].waitForExistence(timeout: 5))
        snapshot(app, "modifier-env-depth-2")
    }

    @MainActor
    func testModifierRecipePropagatesRouterToSheet() {
        let app = launch()
        tap(app, "Modifier")
        tap(app, "Present Sheet Via Modifier")
        XCTAssertTrue(app.staticTexts["modifierSheetEnv"].waitForExistence(timeout: 5),
                      "Sheet content did not render (router missing from environment?)")
        XCTAssertEqual(text(app, "modifierSheetEnv"), "Modifier sheet has router: modifier-sheet")
        snapshot(app, "modifier-sheet-env")

        tap(app, "Close Modifier Sheet")
        XCTAssertTrue(app.buttons["Present Sheet Via Modifier"].waitForExistence(timeout: 5))
    }

    // MARK: - Boundary cases

    @MainActor
    func testRapidDuplicatePushesCollapseToOne() {
        let app = launch()
        tap(app, "Async Lab")
        tap(app, "Rapid Tap Stress Test (10x in 100ms)")
        assertVisible(app, "Stress step 999")
        snapshot(app, "rapid-tap-single-screen")

        // One back tap must return to the root: only one screen was pushed
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["labStackCount"].waitForExistence(timeout: 5))
        XCTAssertEqual(text(app, "labStackCount"), "Stack items: 0")
    }

    @MainActor
    func testDeepLinkBeyondMaxDepthIsTruncatedAndFurtherPushRejected() {
        let app = launch()
        tap(app, "Deep Link 35 Screens")
        assertVisible(app, "Step Screen #30")
        snapshot(app, "deep-link-truncated-at-30")

        // At maxDepth the push is rejected: still on step 30
        tap(app, "Push Step #31")
        XCTAssertFalse(app.staticTexts["Step Screen #31"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Step Screen #30"].exists)

        tap(app, "Pop to Root")
        XCTAssertTrue(app.staticTexts["lastResult"].waitForExistence(timeout: 5))
        XCTAssertEqual(text(app, "lastResult"), "Last result: deep link truncated")
        XCTAssertEqual(text(app, "depthLabel"), "Current Stack Depth: 0 / 30")
    }

    @MainActor
    func testSheetIsRejectedWhileCoverIsPresented() {
        let app = launch()
        tap(app, "Present Full Screen Cover")
        assertVisible(app, "Full Screen Cover: cover-1")

        tap(app, "Try Present Sheet From Same Router")
        XCTAssertTrue(app.staticTexts["Sheet attempt: rejected"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Blocked"].waitForExistence(timeout: 2), "No sheet may appear over the cover")
        XCTAssertTrue(app.staticTexts["Full Screen Cover: cover-1"].exists, "Cover must stay presented")
        snapshot(app, "cover-rejects-sheet")

        tap(app, "Dismiss Cover")
        XCTAssertTrue(app.staticTexts["depthLabel"].waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    @MainActor
    private func tap(_ app: XCUIApplication, _ title: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[title].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Button '\(title)' not found", file: file, line: line)
        button.tap()
    }

    @MainActor
    private func assertVisible(_ app: XCUIApplication, _ label: String, timeout: TimeInterval = 5,
                               file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.staticTexts[label].waitForExistence(timeout: timeout), "'\(label)' not shown", file: file, line: line)
    }

    @MainActor
    private func text(_ app: XCUIApplication, _ identifier: String) -> String {
        app.staticTexts[identifier].label
    }

    @MainActor
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
