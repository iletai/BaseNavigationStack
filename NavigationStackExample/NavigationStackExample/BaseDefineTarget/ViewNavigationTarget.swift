//
//  ViewNavigationTarget.swift
//  NavigationStackExample
//
//  Created by iletai on 14/12/2023.
//

import Foundation
import BaseNavigationStack
import SwiftUI

public enum ViewNavigationTarget: BaseViewProtocol {
    public func withNavigationDestination() -> some View {
        switch self {
        case .policy(_):
            PolicyView()
        case .list:
            ListView()
        case .splash:
            SplashView()
        default:
            EmptyView()
        }
    }
    
    public static func == (lhs: ViewNavigationTarget, rhs: ViewNavigationTarget) -> Bool {
        lhs.id == rhs.id
    }
    
    public var id: String {
        switch self {
        case .policy(_):
            return "policy"
        case .updateProfile(_):
            return "updateProfile"
        case .splash:
            return "splash"
        case .main:
            return "main"
        case .list:
            return "list"
        }
    }

    case splash
    case main
    case list
    case policy(URL)
    case updateProfile(() -> Void?)

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .splash:
            hasher.combine("splash")
        case .main:
            hasher.combine("main")
        case .list:
            hasher.combine("list")
        case .policy(let url):
            hasher.combine("policy")
            hasher.combine(url)
        case .updateProfile(let closure):
            hasher.combine("updateProfile")
            hasher.combine(ObjectIdentifier(closure as AnyObject))
        }
    }

    public func withSheetDestination() -> some View {
        switch self {
        case .policy(_):
            PolicyView()
                .presentationDetents(self.detent)
        case .list:
            ListView()
                .presentationDetents(self.detent)
        case .splash:
            SplashView()
                .presentationDetents(self.detent)
        default:
            EmptyView()
        }
    }

    public func withFullScreenDestination() -> some View {
        switch self {
        case .policy(_):
            PolicyView()
        case .list:
            ListView()
        case .splash:
            SplashView()
        default:
            EmptyView()
        }
    }

    public var detent: Set<PresentationDetent> {
        switch self {
        case .splash:
            return [.large]
        case .main:
            return [.large]
        case .list:
            return [.large]
        case .policy(_):
            return [.large]
        case .updateProfile(_):
            return [.large]
        }
    }
}
