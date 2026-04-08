//
//  ThemeController.swift
//  Ortio
//
//  Created by OpenAI on 08.04.2026.
//

import SwiftUI

@MainActor
final class ThemeController: ObservableObject {
    @Published var selectedTheme: Theme = .system

    func applyStoredTheme(from users: [User]) {
        guard let user = users.first else { return }
        apply(theme: user.theme)
    }

    func apply(theme: Theme) {
        selectedTheme = theme
    }
}
