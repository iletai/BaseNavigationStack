//
//  ContentView.swift
//  NavigationStackExample
//
//  Created by iletai on 14/12/2023.
//

import SwiftUI
import BaseNavigationStack
import Foundation

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

#Preview {
    ContentView()
}
