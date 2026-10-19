// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BaseNavigationStack",
    platforms: [
        .macOS(.v14), .iOS(.v17)
    ],
    products: [
        .library(
            name: "BaseNavigationStack",
            targets: ["BaseNavigationStack"]
        ),
    ],
    targets: [
        .target(
            name: "BaseNavigationStack",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "BaseNavigationStackTests",
            dependencies: ["BaseNavigationStack"]
        ),
    ]
)
