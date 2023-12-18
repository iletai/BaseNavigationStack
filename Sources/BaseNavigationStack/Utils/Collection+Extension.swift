//
//  Collection+Extension.swift
//
//
//  Created by Lê Quang Trọng Tài on 12/17/23.
//

import Foundation

extension Collection {
    subscript (safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Array {
    mutating func removeLastSafe() {
        guard !isEmpty else { return }
        removeLast()
    }

    mutating func removeAllSafe() {
        guard !isEmpty else { return }
        removeAll()
    }
}
