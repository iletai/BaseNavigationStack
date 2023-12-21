//
//  BaseNavigationView.swift
//
//
//  Created by iletai on 20/12/2023.
//

import Foundation
import SwiftUI
import Combine

public struct BaseNavigationView<RootView: View, ScreenView>: View where ScreenView: BaseViewProtocol {
    public typealias BaseNavigation = BaseNavigationStack<ScreenView>
    /// Base Navigation Stack Root View
    public let rootView: RootView

    @State
    private var navigationRouter = BaseNavigation(isPresented: .constant(nil))

    public init(@ViewBuilder rootView: @escaping () -> RootView) {
        self.rootView = rootView()
    }

    public var body: some View {
        NavigationStack(path: navigationRouter.navigationPath) {
            rootView
                .navigationDestination(for: ScreenView.self) { screen in
                    screen.withNavigationDestination()
                }
                .sheet(item: navigationRouter.presentingSheet) { item in
                    item.withSheetDestination()
                }
                .fullScreenCover(item: navigationRouter.presentingFullScreen, content: { fullScreen in
                    fullScreen.withFullScreenDestination()
                })
                .environment(\.openURL, OpenURLAction {
                    navigationRouter.handleOpenURL(url: $0)
                })
        }
        .environment(navigationRouter)
    }
}
