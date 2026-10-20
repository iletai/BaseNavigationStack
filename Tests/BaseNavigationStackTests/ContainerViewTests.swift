import XCTest
import SwiftUI
@testable import BaseNavigationStack

enum ContainerTestRoute: Hashable, Sendable {
    case detail
}

struct ContainerTestSheet: Identifiable, Hashable, Sendable {
    let id: String
}

@MainActor
final class ContainerViewTests: XCTestCase {

    func testContainerInitialization() {
        let router = NavigationRouter<ContainerTestRoute, ContainerTestSheet, ContainerTestSheet>()

        let container = BaseNavigationContainer(
            router: router,
            content: { Text("Root") },
            destination: { _ in Text("Detail") },
            sheet: { sheet in Text("Sheet: \(sheet.id)") },
            cover: { cover in Text("Cover: \(cover.id)") }
        )

        XCTAssertNotNil(container.body)
    }

    func testModifierApplication() {
        let router = NavigationRouter<ContainerTestRoute, ContainerTestSheet, ContainerTestSheet>()

        let view = Text("Hello")
            .navigationRouter(
                router,
                destination: { _ in Text("Dest") }
            )

        XCTAssertNotNil(view)
    }
}
