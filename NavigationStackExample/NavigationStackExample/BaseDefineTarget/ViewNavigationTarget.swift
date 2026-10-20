//
//  ViewNavigationTarget.swift
//  NavigationStackExample
//
//  Created by iletai on 14/12/2023.
//

import Foundation
import BaseNavigationStack
import SwiftUI

/// Legacy v1 router alias used by the original demo views (ListView, PolicyView, BaseView).
public typealias BaseNavigation = BaseNavigationStack<ViewNavigationTarget>

public enum ViewNavigationTarget: BaseViewProtocol {
    case splash
    case main
    case list
    case policy(URL)
    case updateProfile(userID: String)

    public var id: String {
        switch self {
        case .policy(let url):
            return "policy-\(url.absoluteString)"
        case .updateProfile(let id):
            return "updateProfile-\(id)"
        case .splash:
            return "splash"
        case .main:
            return "main"
        case .list:
            return "list"
        }
    }

    public static func == (lhs: ViewNavigationTarget, rhs: ViewNavigationTarget) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    @MainActor
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

    @MainActor
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

    @MainActor
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
        case .splash, .main, .list, .policy, .updateProfile:
            return [.large]
        }
    }
}
