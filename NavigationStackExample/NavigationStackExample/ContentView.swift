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
                    VStack(spacing: 20) {
                        Text("Full Screen Cover: \(cover.id)")
                            .font(.largeTitle)
                        Button("Dismiss Cover") {
                            router.dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
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
        }
    }
}

// MARK: - Stack Explorer

struct StackExplorerView: View {
    @Environment(DemoRouter.self) private var router

    var body: some View {
        VStack(spacing: 20) {
            Text("BaseNavigationStack 2.0")
                .font(.headline)
            Text("Current Stack Depth: \(router.path.count) / \(router.maxDepth)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

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
                    router.push(.step(router.path.count + 1))
                }
                .buttonStyle(.borderedProminent)

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
                    Task.detached {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        labRouter.send { r in
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
