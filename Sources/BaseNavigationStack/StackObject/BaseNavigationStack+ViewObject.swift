//
//  BaseNavigationStack+ViewObject.swift
//
//
//  Created by iletai on 15/12/2023.
//

import SwiftUI

extension BaseNavigationStack {
    /// With Navigation Path In Navigation Stack
    /// We Need Break To An Array For Control List Item In Navigation
    struct RootingState {
        /// All View When Push To Navigation Stack
        var navigationPath = [ScreenView]()

        /// View Is Presenting In Navigation Stack
        var presentingSheet: ScreenView? = nil

        /// View Is Presenting Full
        var presentingFullScreen: ScreenView? = nil

        /// View Is Presenting Modal
        var presentingModal: ScreenView? = nil

        /// Status Is Presenting A View
        var isPresented: Binding<ScreenView?>

        var isPresenting: Bool {
            return presentingSheet != nil || presentingFullScreen != nil || presentingModal != nil
        }
        
        /// Initial
        /// - Parameter isPresented: With Router Stack Init View.
        init(isPresented: Binding<ScreenView?>) {
            self.isPresented = isPresented
        }
    }
}
