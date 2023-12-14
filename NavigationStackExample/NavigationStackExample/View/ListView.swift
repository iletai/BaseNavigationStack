//
//  ListView.swift
//  NavigationStackExample
//
//  Created by iletai on 14/12/2023.
//

import Foundation
import SwiftUI
import BaseNavigationStack

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

struct SplashView: View {
    @Environment(BaseNavigationStack<ViewNavigationTarget, SheetViewPresentTarget>.self)
    var navigationRouter
    
    var body: some View {
        VStack {
            Text("List View")
                .font(.title)
                .fontWeight(.bold)
            HStack {
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

