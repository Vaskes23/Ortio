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

    /// Prevents initial preference hydration from immediately writing the same values back to `UserDefaults`.
    @ObservationIgnored
    private var isBootstrappingPreferences = true

    /// Push notification preference mirrored into `UserDefaults` after initialization.
    var notificationsEnabled: Bool {
        didSet { persistPreferencesIfReady() }
    }

    /// Sound effects preference mirrored into `UserDefaults` after initialization.
    var soundEffectsEnabled: Bool {
        didSet { persistPreferencesIfReady() }
    }

    /// Email updates preference mirrored into `UserDefaults` after initialization.
    var receiveEmailsEnabled: Bool {
        didSet { persistPreferencesIfReady() }
    }

    /// Editable display name staged by the profile editor before save.
    var name: String = "Placeholder User"

    /// Current SwiftData user record backing the settings screen.
    var user: User = User()

    /// Whether account settings are unlocked through Apple.
    var isSignedInWithApple: Bool {
        user.isSignedInWithApple
    }

    /// Whether account settings are unlocked through Google.
    var isSignedInWithGoogle: Bool {
        user.isSignedInWithGoogle
    }

    /// Whether any supported provider has unlocked account-owned settings.
    var isAuthenticated: Bool {
        user.isAuthenticated
    }

    /// Set when a save operation fails. Drives the error alert in SettingsView.
    var errorMessage: String?

    /// Creates the settings state model and hydrates local preference flags.
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

    /// Saves a theme selection to SwiftData.
    func saveTheme(_ theme: Theme, context: ModelContext) {
        do {
            try repository.saveTheme(theme, for: user, context: context)
        } catch {
            Self.logger.error("Failed to save theme: \(error)")
            errorMessage = "Failed to save theme: \(error.localizedDescription)"
        }
    }

    /// Completes Apple authorization by storing the minimal Apple identity returned by AuthenticationServices.
    func completeAppleSignIn(
        identifier: String,
        email: String?,
        fullName: PersonNameComponents?,
        context: ModelContext
    ) {
        do {
            try repository.saveAppleAccount(
                identifier: identifier,
                email: email,
                fullName: fullName,
                for: user,
                context: context
            )
            name = user.name
        } catch {
            Self.logger.error("Failed to save Apple account: \(error)")
            errorMessage = "Failed to save Apple sign-in: \(error.localizedDescription)"
        }
    }

    /// Completes Google authorization by storing the compact profile returned by `GoogleSignInService`.
    func completeGoogleSignIn(_ profile: GoogleAccountProfile, context: ModelContext) {
        do {
            try repository.saveGoogleAccount(
                email: profile.email,
                fullName: profile.fullName,
                profileImageData: profile.avatarData,
                for: user,
                context: context
            )
            name = user.name
        } catch {
            Self.logger.error("Failed to save Google account: \(error)")
            errorMessage = "Failed to save Google sign-in: \(error.localizedDescription)"
        }
    }

    /// Persists profile editor changes and returns whether SwiftData accepted the update.
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

    /// Writes preference toggles only after initialization has finished.
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
