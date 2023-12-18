//
//  PolicyView.swift
//  NavigationStackExample
//
//  Created by iletai on 15/12/2023.
//

import Foundation
import SwiftUI
import BaseNavigationStack

struct PolicyView: View {
    @Environment(BaseNavigation.self) var navigationRouter
    @Environment(\.dismiss) var dimiss
    var body: some View {
        VStack {
            Text("Policy")
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
                    navigationRouter.pushToView(.list)
                } label: {
                    Text("List")
                }
                Button {
                    navigationRouter.presentSheet(.list)
                } label: {
                    Text("Present List")
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
                Button {
                    navigationRouter.presentFullScreen(.list)
                } label: {
                    Text("Present Full View")
                }
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .navigationTitle("Policy")
    }
}
