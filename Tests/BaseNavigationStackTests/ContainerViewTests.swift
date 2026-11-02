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

        // Smoke test: body must build on every platform branch without trapping
        _ = container.body
    }

    func testModifierApplication() {
        let router = NavigationRouter<ContainerTestRoute, ContainerTestSheet, ContainerTestSheet>()

        _ = Text("Hello")
            .navigationRouter(
                router,
                destination: { _ in Text("Dest") }
            )
    }
}
