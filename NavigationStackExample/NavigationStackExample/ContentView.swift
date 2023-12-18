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
    @State
    var navigationRouter = BaseNavigation(isPresented: .constant(.splash))
    
    var body: some View {
        NavigationStack(path: navigationRouter.navigationPath) {
            BaseView()
                .withNavigationRouter()
                .withSheetRouter(sheetDestination: navigationRouter.presentingSheet)
                .withFullScreenRouter(navigationRouter.presentingFullScreen)
        }
        .environment(navigationRouter)
    }
}

#Preview {
    ContentView()
}
