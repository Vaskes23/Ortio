//
//  SettingsViewModel.swift
//  Ortio
//
//  Created by Matyas Vascak on 22.06.2024.
//

import Foundation
import SwiftData
import Observation
import os

/// Manages settings state: notification preferences (UserDefaults), theme (SwiftData), and user profile.
@Observable
class SettingsViewModel {
    @ObservationIgnored
    private static let logger = Logger(
        subsystem: OrtioApp.subsystem,
        category: "SettingsViewModel"
    )

    var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }
    var soundEffectsEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEffectsEnabled, forKey: "soundEffectsEnabled") }
    }
    var receiveEmailsEnabled: Bool {
        didSet { UserDefaults.standard.set(receiveEmailsEnabled, forKey: "receiveEmailsEnabled") }
    }
    var name: String = "Placeholder User"
    var selectedTheme: Theme = .system
    var user: User = User()

    /// Set when a save operation fails. Drives the error alert in SettingsView.
    var errorMessage: String?

    init() {
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.soundEffectsEnabled = UserDefaults.standard.bool(forKey: "soundEffectsEnabled")
        self.receiveEmailsEnabled = UserDefaults.standard.bool(forKey: "receiveEmailsEnabled")
    }

    /// Loads the existing user from SwiftData, or creates a default one if none exists.
    func loadUser(from users: [User], context: ModelContext) {
        if let existingUser = users.first {
            user = existingUser
            name = user.name
            selectedTheme = user.theme
        } else {
            user = User()
            context.insert(user)
            do {
                try context.save()
                name = user.name
                selectedTheme = user.theme
            } catch {
                Self.logger.error("Failed to save default user: \(error)")
            }
        }
    }

    /// Persists the selected theme to SwiftData.
    func saveTheme(context: ModelContext) {
        user.theme = selectedTheme
        do {
            try context.save()
        } catch {
            Self.logger.error("Failed to save theme: \(error)")
            errorMessage = "Failed to save theme: \(error.localizedDescription)"
        }
    }
}
