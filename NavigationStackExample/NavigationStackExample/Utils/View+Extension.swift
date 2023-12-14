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
    
    func withSheetRouter(sheetDestination: Binding<SheetViewPresentTarget?>) -> some View {
        sheet(item: sheetDestination) { toSheet in
            switch toSheet {
            case .policy(let linkTargetOpen):
                Text(linkTargetOpen.absoluteString)
            case .updateProfile( _):
                EmptyView()
            }
        }
    }
}
