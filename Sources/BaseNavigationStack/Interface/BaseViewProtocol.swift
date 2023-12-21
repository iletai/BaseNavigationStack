//
//  PresentViewProtocol.swift
//
//
//  Created by iletai on 18/12/2023.
//

import Foundation
import SwiftUI

public protocol BaseViewProtocol: Identifiable, Hashable {
    associatedtype PresentSheetScreenView: View
    associatedtype DestinationView: View
    associatedtype PresentFullScreenView: View

    @MainActor
    @ViewBuilder
    func withSheetDestination() -> PresentSheetScreenView

    @ViewBuilder
    func withFullScreenDestination() -> PresentFullScreenView

    @MainActor
    @ViewBuilder
    func withNavigationDestination() -> DestinationView
}
