//
//  SettingsViewModel.swift
//  Ortio
//
//  Created by Matyas Vascak on 22.06.2024.
//

import Foundation
import SwiftData
import Observation
import UIKit
import os

/// Manages settings state: notification preferences (UserDefaults), theme (SwiftData), and user profile.
@MainActor
@Observable
class SettingsViewModel {
    @ObservationIgnored
    private static let logger = Logger(
        subsystem: OrtioApp.subsystem,
        category: "SettingsViewModel"
    )

    @ObservationIgnored
    private let repository: UserSettingsRepositoryProtocol

    @ObservationIgnored
    private var isBootstrappingPreferences = true

    var notificationsEnabled: Bool {
        didSet { persistPreferencesIfReady() }
    }
    var soundEffectsEnabled: Bool {
        didSet { persistPreferencesIfReady() }
    }
    var receiveEmailsEnabled: Bool {
        didSet { persistPreferencesIfReady() }
    }
    var name: String = "Placeholder User"
    var user: User = User()

    /// Set when a save operation fails. Drives the error alert in SettingsView.
    var errorMessage: String?

    init(repository: UserSettingsRepositoryProtocol = UserSettingsRepository()) {
        self.repository = repository
        let preferences = repository.loadPreferences()
        self.notificationsEnabled = preferences.notificationsEnabled
        self.soundEffectsEnabled = preferences.soundEffectsEnabled
        self.receiveEmailsEnabled = preferences.receiveEmailsEnabled
        self.isBootstrappingPreferences = false
    }

    /// Loads the existing user from SwiftData, or creates a default one if none exists.
    func loadUser(from users: [User], context: ModelContext) {
        do {
            user = try repository.loadOrCreateUser(from: users, context: context)
            name = user.name
        } catch {
            Self.logger.error("Failed to load user: \(error)")
            errorMessage = "Failed to load settings: \(error.localizedDescription)"
        }
    }

    func saveTheme(_ theme: Theme, context: ModelContext) {
        do {
            try repository.saveTheme(theme, for: user, context: context)
        } catch {
            Self.logger.error("Failed to save theme: \(error)")
            errorMessage = "Failed to save theme: \(error.localizedDescription)"
        }
    }

    func saveProfile(username: String, selectedImage: UIImage?, context: ModelContext) -> Bool {
        do {
            try repository.saveProfile(
                name: name,
                username: username,
                selectedImage: selectedImage,
                for: user,
                context: context
            )
            return true
        } catch {
            Self.logger.error("Failed to save profile: \(error)")
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            return false
        }
    }

    private func persistPreferencesIfReady() {
        guard !isBootstrappingPreferences else { return }
        repository.savePreferences(
            UserSettingsPreferences(
                notificationsEnabled: notificationsEnabled,
                soundEffectsEnabled: soundEffectsEnabled,
                receiveEmailsEnabled: receiveEmailsEnabled
            )
        )
    }
}
