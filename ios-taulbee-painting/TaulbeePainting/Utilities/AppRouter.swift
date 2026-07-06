//
//  AppRouter.swift
//  TaulbeePainting
//
//  Lightweight app-wide router: which tab is selected, plus small cross-tab
//  handoffs like drafting a question for the Paint Expert.
//

import SwiftUI

@Observable
final class AppRouter {
    var selectedTab: AppTab = .home

    /// A drafted question the Expert tab picks up into its input field.
    var expertDraft: String?

    /// Jump to the Expert tab with a prefilled (editable) question.
    func askExpert(_ question: String) {
        expertDraft = question
        selectedTab = .expert
    }
}

/// Shared push destinations for the Homeowner Hub, registered in each
/// tab's navigation stack.
enum HubRoute: Hashable {
    case maintenance
    case timeline
}
