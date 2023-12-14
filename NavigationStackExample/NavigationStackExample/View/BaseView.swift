//
//  BaseView.swift
//  NavigationStackExample
//
//  Created by iletai on 14/12/2023.
//

import Foundation
import SwiftUI
import BaseNavigationStack

struct BaseView: View {
    @Environment(BaseNavigationStack<ViewNavigationTarget, SheetViewPresentTarget>.self)
    var navigationRouter
    
    var body: some View {
        VStack {
            Text("Base View")
                .font(.title)
                .fontWeight(.bold)
            HStack {
                Button {
                    navigationRouter.pushToView(.list)
                } label: {
                    Text("Push View")
                }
                Button {
                    navigationRouter.presentSheet(.policy(URL(string: "https://google.com")!))
                } label: {
                    Text("Present View")
                }
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }
}

