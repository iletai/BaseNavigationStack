//
//  Collection+Extension.swift
//
//
//  Created by Lê Quang Trọng Tài on 12/17/23.
//

import Foundation

extension Collection {
    public subscript (safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Array {
    public mutating func removeLastSafe() {
        guard !isEmpty else { return }
        removeLast()
    }
}
