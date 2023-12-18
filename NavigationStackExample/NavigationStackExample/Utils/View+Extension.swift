//
//  View+Extension.swift
//  NavigationStackExample
//
//  Created by iletai on 14/12/2023.
//

import Foundation
import SwiftUI

@MainActor
extension View {
    func withNavigationRouter() -> some View {
        navigationDestination(for: ViewNavigationTarget.self) { pushTo in
            switch pushTo {
            case .list:
                ListView()
            case .splash:
                SplashView()
            default:
                EmptyView()
            }
            
        }
    }
    
    func withSheetRouter(sheetDestination: Binding<ViewNavigationTarget?>) -> some View {
        sheet(item: sheetDestination) { toSheet in
            switch toSheet {
            case .policy(_):
                PolicyView()
            case .list:
                ListView()
            default:
                EmptyView()
            }
        }
    }

    func withFullScreenRouter(_ presentFullView: Binding<ViewNavigationTarget?>) -> some View {
        fullScreenCover(item: presentFullView) { fullView in
            switch fullView {
            case .list:
                ListView()
            case .splash:
                SplashView()
            default:
                EmptyView()
            }
        }
    }
}
