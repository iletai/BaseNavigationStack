#!/usr/bin/env bash
#
# scripts/check-binary-size.sh
# Measures how much BaseNavigationStack adds to a release app binary and fails above a budget.
#
# Builds two tiny macOS SwiftUI apps with -Osize and dead stripping:
#   baseline: plain NavigationStack + sheet
#   withlib:  BaseNavigationContainer with the same routes
# and compares their stripped binary sizes.
#
# Usage: scripts/check-binary-size.sh [budget-bytes]   (default 80000)

set -euo pipefail

BUDGET="${1:-80000}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d -t bnssize.XXXXXX)"
trap 'rm -rf "${WORK}"' EXIT

write_package() {
    local dir="$1" deps="$2" target_deps="$3"
    mkdir -p "${dir}/Sources/Probe"
    cat > "${dir}/Package.swift" <<SWIFT
// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "Probe",
    platforms: [.macOS(.v14)],
    dependencies: [${deps}],
    targets: [
        .executableTarget(
            name: "Probe",
            dependencies: [${target_deps}],
            swiftSettings: [.unsafeFlags(["-Osize"])],
            linkerSettings: [.unsafeFlags(["-Xlinker", "-dead_strip"])]
        )
    ]
)
SWIFT
}

write_package "${WORK}/baseline" "" ""
cat > "${WORK}/baseline/Sources/Probe/main.swift" <<'SWIFT'
import SwiftUI
enum Route: Hashable, Sendable { case a, b(Int) }
struct Item: Identifiable, Hashable, Sendable { let id: Int }
@MainActor @Observable final class Model { var path: [Route] = []; var sheet: Item?; var cover: Item? }
struct Root: View {
    @State private var model = Model()
    var body: some View {
        NavigationStack(path: $model.path) {
            Button("Go") { model.path.append(.a) }
                .navigationDestination(for: Route.self) { Text(String(describing: $0)) }
                .sheet(item: $model.sheet) { Text("\($0.id)") }
        }
    }
}
@main struct ProbeApp: App { var body: some Scene { WindowGroup { Root() } } }
SWIFT

write_package "${WORK}/withlib" ".package(path: \"${REPO_DIR}\")" "\"BaseNavigationStack\""
cat > "${WORK}/withlib/Sources/Probe/main.swift" <<'SWIFT'
import SwiftUI
import BaseNavigationStack
enum Route: Hashable, Sendable { case a, b(Int) }
struct Item: Identifiable, Hashable, Sendable { let id: Int }
struct Root: View {
    @State private var router = NavigationRouter<Route, Item, Item>()
    var body: some View {
        BaseNavigationContainer(router: router) {
            Button("Go") { router.push(.a) }
        } destination: { Text(String(describing: $0)) } sheet: { Text("\($0.id)") } cover: { Text("\($0.id)") }
    }
}
@main struct ProbeApp: App { var body: some Scene { WindowGroup { Root() } } }
SWIFT

size_of() {
    (cd "${WORK}/$1" && swift build -c release 2>&1 | grep -E "error|warning: " >&2 || true)
    cp "${WORK}/$1/.build/release/Probe" "${WORK}/$1.bin"
    strip -x "${WORK}/$1.bin"
    stat -f %z "${WORK}/$1.bin"
}

BASE=$(size_of baseline)
WITH=$(size_of withlib)
DELTA=$((WITH - BASE))

REPORT="Binary size cost of BaseNavigationStack (release, -Osize, dead-stripped, stripped): ${DELTA} bytes (baseline ${BASE}, with library ${WITH}, budget ${BUDGET})"
echo "${REPORT}"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    echo "${REPORT}" >> "${GITHUB_STEP_SUMMARY}"
fi

if [ "${DELTA}" -gt "${BUDGET}" ]; then
    echo "::error::Library adds ${DELTA} bytes, over the ${BUDGET}-byte budget"
    exit 1
fi
