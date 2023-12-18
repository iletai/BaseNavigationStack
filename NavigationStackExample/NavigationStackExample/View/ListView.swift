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
    @Environment(BaseNavigation.self) var navigationRouter
    @Environment(\.dismiss) var dimiss
    var body: some View {
        VStack {
            Text("List View")
                .font(.title)
                .fontWeight(.bold)
            HStack {
                Button {
                    dimiss()
                } label: {
                    Text("Dis")
                }
            }
            HStack {
                Button {
                    navigationRouter.presentSheet(.policy(URL(string: "https://google.com")!))
                } label: {
                    Text("Present View")
                }
                Button {
                    navigationRouter.pushToView(.splash)
                } label: {
                    Text("Splash")
                }
                Button {
                    navigationRouter.popBack()
                } label: {
                    Text("PopBack")
                }
                Button {
                    navigationRouter.navigateToRoot()
                } label: {
                    Text("PopRoot")
                }
                Button {
                    navigationRouter.presentFullScreen(.list)
                } label: {
                    Text("FullView")
                }
                Button {
                    navigationRouter.presentFullScreen(.splash)
                } label: {
                    Text("SplashView")
                }
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .navigationTitle("ListView")
    }
}

struct SplashView: View {
    @Environment(BaseNavigation.self)
    var navigationRouter

    @Environment(\.dismiss) var dimiss

    var body: some View {
        VStack {
            Text("SplashView")
                .font(.title)
                .fontWeight(.bold)
            HStack {
                Button {
                    dimiss()
                } label: {
                    Text("Dis")
                }
                Button {
                    navigationRouter.pushToView(.list)
                } label: {
                    Text("List")
                }
                Button {
                    navigationRouter.popBack()
                } label: {
                    Text("PopBack")
                }
                Button {
                    navigationRouter.navigateToRoot()
                } label: {
                    Text("PopRoot")
                }
                Button {
                    navigationRouter.presentFullScreen(.list)
                } label: {
                    Text("FullView")
                }
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .navigationTitle("Splash")
    }
}

