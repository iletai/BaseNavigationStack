//
//  ContentView.swift
//  NavigationStackExample
//
//  Created by iletai on 14/12/2023.
//

import SwiftUI
import BaseNavigationStack
import Foundation

typealias BaseNavigation = BaseNavigationStack<ViewNavigationTarget>
struct ContentView: View {
    var body: some View {
        BaseNavigationView<SplashView, ViewNavigationTarget> {
            SplashView()
        }
    }
}

#Preview {
    ContentView()
}
