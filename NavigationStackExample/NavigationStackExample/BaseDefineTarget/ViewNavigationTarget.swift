//
//  ViewNavigationTarget.swift
//  NavigationStackExample
//
//  Created by iletai on 14/12/2023.
//

import Foundation

public enum ViewNavigationTarget: Identifiable, Hashable {
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
                // Note: You may want to provide a more specific hash for closures
                // depending on your use case.
                hasher.combine(ObjectIdentifier(closure as AnyObject))
        }
    }
}
