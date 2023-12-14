# BaseNavigationStack
Build a navigation controller with Navigation Stack SwiftUI 

[![Swift Version](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/cocoapods/p/LFAlertController.svg?style=flat)](https://developer.apple.com/ios/)

BaseNavigationStack is a Swift package that provides a flexible and reusable base class for managing navigation stacks in SwiftUI applications.

## Overview

`BaseNavigationStack` is designed to simplify the management of navigation stacks in SwiftUI applications. It introduces a generic approach to handle different types for views and presentation targets. This allows you to build navigation flows with ease, supporting various types of views and presentation styles.

## Example: 

[<video width="640" height="360" controls>
  <video src="https://github.com/iletai/BaseNavigationStack/assets/26614687/9f4ae052-577d-4b99-bf5a-39eee6e75c9a.mp4" type="video/mp4">
</video>](https://github.com/iletai/BaseNavigationStack/assets/26614687/9f4ae052-577d-4b99-bf5a-39eee6e75c9a)


## Installation

### Swift Package Manager

You can use the Swift Package Manager to install `BaseNavigationStack` by adding it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/iletai/BaseNavigationStack.git", from: "1.0.0"),
],
targets: [
    .target(name: "YourTarget", dependencies: ["BaseNavigationStack"]),
]
```

## Usage

1. Import the `BaseNavigationStack` module into your Swift file:

```swift
import BaseNavigationStack
```
2. Build In View:

```swift
struct ContentView: View {
    @State 
    var navigationRouter = BaseNavigationStack<
        ViewNavigationTarget,
        SheetViewPresentTarget
    >(
        isPresented: .constant(.splash)
    )
    
    var body: some View {
        NavigationStack(path: navigationRouter.navigationPath) {
            BaseView()
                .withNavigationRouter()
                .withSheetRouter(sheetDestination: navigationRouter.presentingSheet)
        }
        .environment(navigationRouter)
    }
}
```

3. Quick To Push/Present View
```swift
struct ListView: View {
    @Environment(BaseNavigationStack<ViewNavigationTarget, SheetViewPresentTarget>.self)
    var navigationRouter
    
    var body: some View {
        VStack {
            Text("List View")
                .font(.title)
                .fontWeight(.bold)
            HStack {
                Button {
                    navigationRouter.pushToView(.splash)
                } label: {
                    Text("Splash")
                }
                Button {
                    navigationRouter.popBack()
                } label: {
                    Text("Pop Back")
                }
                Button {
                    navigationRouter.navigateToRoot()
                } label: {
                    Text("Pop To Root")
                }
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }
}
```
