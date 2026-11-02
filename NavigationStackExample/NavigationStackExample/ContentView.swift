//
//  ContentView.swift
//  NavigationStackExample
//
//  Created by iletai on 14/12/2023.
//

import SwiftUI
import BaseNavigationStack

// MARK: - Routes Definition

enum DemoRoute: Hashable, Sendable {
    case step(Int)
    case detail(title: String)
}

struct DemoSheet: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
}

struct DemoCover: Identifiable, Hashable, Sendable {
    let id: String
}

typealias DemoRouter = NavigationRouter<DemoRoute, DemoSheet, DemoCover>

// MARK: - Root Interactive Showcase View

struct ContentView: View {
    @State private var router = DemoRouter()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Stack Explorer
            BaseNavigationContainer(
                router: router,
                content: {
                    StackExplorerView()
                },
                destination: { route in
                    switch route {
                    case .step(let count):
                        StepDetailView(stepIndex: count)
                    case .detail(let title):
                        VStack(spacing: 16) {
                            Text("Detail View: \(title)")
                                .font(.title2)
                            Button("Dismiss Screen") {
                                router.dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                },
                sheet: { sheet in
                    NestedSheetContainerView(sheet: sheet)
                },
                cover: { cover in
                    CoverView(cover: cover)
                }
            )
            .tabItem {
                Label("Stack", systemImage: "square.stack.3d.up")
            }
            .tag(0)

            // Tab 2: Async & Concurrency Lab
            AsyncLabView()
                .tabItem {
                    Label("Async Lab", systemImage: "bolt.horizontal")
                }
                .tag(1)

            // Tab 3: `.navigationRouter` modifier on a hand-built NavigationStack
            ModifierRecipeView()
                .tabItem {
                    Label("Modifier", systemImage: "wand.and.stars")
                }
                .tag(2)
        }
    }
}

// MARK: - Stack Explorer

struct StackExplorerView: View {
    @Environment(DemoRouter.self) private var router
    @State private var lastResult = "none"

    var body: some View {
        VStack(spacing: 20) {
            Text("BaseNavigationStack 2.0")
                .font(.headline)
            Text("Current Stack Depth: \(router.path.count) / \(router.maxDepth)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("depthLabel")
            Text("Last result: \(lastResult)")
                .font(.caption)
                .accessibilityIdentifier("lastResult")

            // Breadcrumb Trail
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Text("Root")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())

                    ForEach(router.path, id: \.self) { route in
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("\(String(describing: route))")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
            }

            Divider()

            VStack(spacing: 12) {
                Button("Push Next Step") {
                    lastResult = router.push(.step(router.path.count + 1)) ? "push accepted" : "push rejected"
                }
                .buttonStyle(.borderedProminent)

                Button("Present Full Screen Cover") {
                    router.present(cover: DemoCover(id: "cover-1"))
                }
                .buttonStyle(.bordered)

                Button("Deep Link 35 Screens") {
                    let routes = (1...35).map { DemoRoute.step($0) }
                    lastResult = router.replacePath(routes) ? "deep link full" : "deep link truncated"
                }
                .buttonStyle(.bordered)

                Button("Present Modal Sheet") {
                    router.present(sheet: DemoSheet(id: "modal-1", title: "Nested Flow Sheet"))
                }
                .buttonStyle(.bordered)

                Button("Pop Back") {
                    router.pop()
                }
                .buttonStyle(.bordered)
                .disabled(router.path.isEmpty)

                Button("Pop to Root") {
                    router.popToRoot()
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.red)
                .disabled(router.path.isEmpty)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Explorer")
    }
}

struct StepDetailView: View {
    let stepIndex: Int
    @Environment(DemoRouter.self) private var router

    var body: some View {
        VStack(spacing: 20) {
            Text("Step Screen #\(stepIndex)")
                .font(.title)

            Button("Push Step #\(stepIndex + 1)") {
                router.push(.step(stepIndex + 1))
            }
            .buttonStyle(.borderedProminent)

            Button("Pop Back") {
                router.pop()
            }
            .buttonStyle(.bordered)

            Button("Pop to Root") {
                router.popToRoot()
            }
            .buttonStyle(.bordered)
            .foregroundStyle(.red)
        }
        .padding()
        .navigationTitle("Step \(stepIndex)")
    }
}

// MARK: - Full Screen Cover

struct CoverView: View {
    let cover: DemoCover
    @Environment(DemoRouter.self) private var router
    @State private var sheetAttempt = "none"

    var body: some View {
        VStack(spacing: 20) {
            Text("Full Screen Cover: \(cover.id)")
                .font(.largeTitle)
            Text("Sheet attempt: \(sheetAttempt)")
                .accessibilityIdentifier("sheetAttempt")
            Button("Try Present Sheet From Same Router") {
                sheetAttempt = router.present(sheet: DemoSheet(id: "blocked", title: "Blocked")) ? "presented" : "rejected"
            }
            .buttonStyle(.bordered)
            Button("Dismiss Cover") {
                router.dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Modifier Recipe

/// Uses only `.navigationRouter` inside a hand-built stack, without injecting the router
/// on the stack itself, to check that pushed destinations still receive it.
struct ModifierRecipeView: View {
    @State private var modifierRouter = DemoRouter()

    var body: some View {
        NavigationStack(path: $modifierRouter.path) {
            VStack(spacing: 16) {
                Button("Push Via Modifier") {
                    modifierRouter.push(.step(1))
                }
                .buttonStyle(.borderedProminent)

                Button("Present Sheet Via Modifier") {
                    modifierRouter.present(sheet: DemoSheet(id: "modifier-sheet", title: "Modifier Sheet"))
                }
                .buttonStyle(.bordered)
            }
            .navigationTitle("Modifier")
            .navigationRouter(
                modifierRouter,
                destination: { route in ModifierDestinationView(route: route) },
                sheet: { _ in ModifierSheetView() },
                cover: { _ in EmptyView() }
            )
        }
    }
}

struct ModifierDestinationView: View {
    let route: DemoRoute
    @Environment(DemoRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Text("Env router depth: \(router.path.count)")
                .accessibilityIdentifier("modifierEnvDepth")
            Button("Push Another Via Env") {
                if case .step(let index) = route {
                    router.push(.step(index + 1))
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Modifier Detail")
    }
}

struct ModifierSheetView: View {
    @Environment(DemoRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Text("Modifier sheet has router: \(router.sheet?.id ?? "none")")
                .accessibilityIdentifier("modifierSheetEnv")
            Button("Close Modifier Sheet") {
                router.dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Nested Modal Sub-Router View

enum SubModalRoute: Hashable, Sendable {
    case subDetail
}

typealias SubRouter = NavigationRouter<SubModalRoute, DemoSheet, DemoCover>

struct NestedSheetContainerView: View {
    let sheet: DemoSheet
    @State private var subRouter = SubRouter()
    @Environment(DemoRouter.self) private var parentRouter

    var body: some View {
        BaseNavigationContainer(
            router: subRouter,
            content: {
                VStack(spacing: 20) {
                    Text(sheet.title)
                        .font(.title2)
                    Text("This sheet owns an isolated child router")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Push Child Stack Screen") {
                        subRouter.push(.subDetail)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Dismiss Entire Sheet") {
                        parentRouter.dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .navigationTitle("Sheet Root")
            },
            destination: { route in
                switch route {
                case .subDetail:
                    VStack(spacing: 16) {
                        Text("Child Stack Detail")
                        Button("Pop Child Screen") {
                            subRouter.pop()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .navigationTitle("Child Detail")
                }
            }
        )
    }
}

// MARK: - Async & Stress Lab

struct AsyncLabView: View {
    @State private var labRouter = DemoRouter()
    @State private var statusLog: [String] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack(path: $labRouter.path) {
            VStack(spacing: 16) {
                Text("Async & Concurrency Guard Lab")
                    .font(.headline)

                if isLoading {
                    ProgressView("Simulating Background Network Call...")
                }

                Button("Simulate Background Async Push") {
                    isLoading = true
                    let router = labRouter
                    Task.detached {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        router.send { r in
                            isLoading = false
                            r.push(.detail(title: "Loaded from Network Actor"))
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)

                Button("Rapid Tap Stress Test (10x in 100ms)") {
                    for _ in 1...10 {
                        labRouter.push(.step(999))
                    }
                }
                .buttonStyle(.bordered)

                Text("Stack items: \(labRouter.path.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("labStackCount")

                Spacer()
            }
            .padding()
            .navigationTitle("Async Lab")
            .navigationDestination(for: DemoRoute.self) { route in
                switch route {
                case .detail(let title):
                    Text(title)
                case .step(let id):
                    Text("Stress step \(id)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
