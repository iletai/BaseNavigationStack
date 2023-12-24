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
    @State var baseNavigation = BaseNavigation(isPresented: .constant(nil))
    var body: some View {
        NavigationStack(path: baseNavigation.navigationPath) {
            SplashView()
                .withNavigationRouter()
                .withSheetRouter(sheetDestination: baseNavigation.presentingSheet)
                .withFullScreenRouter(baseNavigation.presentingFullScreen)
        }
        .environment(baseNavigation)
    }
}

#Preview {
    ContentView()
}
