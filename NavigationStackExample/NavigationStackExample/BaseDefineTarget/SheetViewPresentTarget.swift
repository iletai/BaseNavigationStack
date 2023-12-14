//
//  SheetViewPresentTarget.swift
//  NavigationStackExample
//
//  Created by iletai on 14/12/2023.
//

import Foundation

public enum SheetViewPresentTarget: Hashable, Identifiable {
    public var id: Self { self }
    
    public static func == (lhs: SheetViewPresentTarget, rhs: SheetViewPresentTarget) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .policy(let uRL):
            hasher.combine(uRL)
        case .updateProfile(_):
            break
        }
    }
    
    case policy(URL)
    case updateProfile(() -> Void?)
}
