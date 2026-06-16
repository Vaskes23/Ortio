//
//  UserSettingsRepository.swift
//  Ortio
//
//  Created by OpenAI on 08.04.2026.
//

import Foundation
import SwiftData
import UIKit

/// UserDefaults-backed settings toggles that are not part of the SwiftData user profile.
struct UserSettingsPreferences: Equatable {
    /// Whether local push-style reminders are enabled in settings.
    var notificationsEnabled: Bool

    /// Whether in-app sound effects are enabled.
    var soundEffectsEnabled: Bool

    /// Whether the user opted into product/update emails.
    var receiveEmailsEnabled: Bool
}

/// Persistence boundary for profile, theme, and simple settings preferences.
///
/// Settings view models use this protocol so tests can replace SwiftData and
/// `UserDefaults` writes with deterministic mocks.
@MainActor
protocol UserSettingsRepositoryProtocol {
    /// Reads non-profile settings from `UserDefaults`.
    func loadPreferences() -> UserSettingsPreferences

    /// Persists non-profile settings to `UserDefaults`.
    func savePreferences(_ preferences: UserSettingsPreferences)

    /// Returns the first persisted user or creates the placeholder profile used before sign-in.
    func loadOrCreateUser(from users: [User], context: ModelContext) throws -> User

    /// Stores the selected appearance theme on the SwiftData user record.
    func saveTheme(_ theme: Theme, for user: User, context: ModelContext) throws

    /// Stores the minimum Apple account identity needed to unlock account settings.
    ///
    /// The stable Apple user identifier is retained because Apple may only send
    /// email and full name during the first authorization.
    func saveAppleAccount(
        identifier: String,
        email: String?,
        fullName: PersonNameComponents?,
        for user: User,
        context: ModelContext
    ) throws

    /// Stores the minimum Google profile data needed after Google Sign-In succeeds.
    ///
    /// Google access and refresh tokens are intentionally not accepted here; the
    /// SDK owns them in Keychain.
    func saveGoogleAccount(
        email: String,
        fullName: String?,
        profileImageData: Data?,
        for user: User,
        context: ModelContext
    ) throws

    /// Saves user-editable profile fields without changing the authenticated account identity.
    func saveProfile(
        name: String,
        username: String,
        selectedImage: UIImage?,
        for user: User,
        context: ModelContext
    ) throws
}

/// Production settings repository backed by SwiftData `User` and `UserDefaults`.
@MainActor
final class UserSettingsRepository: UserSettingsRepositoryProtocol {
    /// `UserDefaults` keys for settings that are intentionally outside SwiftData.
    private enum Keys {
        static let notificationsEnabled = "notificationsEnabled"
        static let soundEffectsEnabled = "soundEffectsEnabled"
        static let receiveEmailsEnabled = "receiveEmailsEnabled"
    }

    /// Backing defaults store. Marked nonisolated because `UserDefaults` itself is thread-safe.
    nonisolated(unsafe) private let userDefaults: UserDefaults

    /// Creates a repository backed by the provided defaults suite.
    nonisolated init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Reads local settings flags, using `false` when a key has not been written yet.
    func loadPreferences() -> UserSettingsPreferences {
        UserSettingsPreferences(
            notificationsEnabled: userDefaults.bool(forKey: Keys.notificationsEnabled),
            soundEffectsEnabled: userDefaults.bool(forKey: Keys.soundEffectsEnabled),
            receiveEmailsEnabled: userDefaults.bool(forKey: Keys.receiveEmailsEnabled)
        )
    }

    /// Writes all settings flags as a single snapshot to avoid partial preference state.
    func savePreferences(_ preferences: UserSettingsPreferences) {
        userDefaults.set(preferences.notificationsEnabled, forKey: Keys.notificationsEnabled)
        userDefaults.set(preferences.soundEffectsEnabled, forKey: Keys.soundEffectsEnabled)
        userDefaults.set(preferences.receiveEmailsEnabled, forKey: Keys.receiveEmailsEnabled)
    }

    /// Loads the persisted user or inserts the locked placeholder profile shown before sign-in.
    func loadOrCreateUser(from users: [User], context: ModelContext) throws -> User {
        if let existingUser = users.first {
            return existingUser
        }

        let user = User()
        context.insert(user)
        try context.save()
        return user
    }

    /// Persists the user's selected theme on the profile row.
    func saveTheme(_ theme: Theme, for user: User, context: ModelContext) throws {
        user.theme = theme
        try context.save()
    }

    /// Saves Apple identity fields and applies Apple's display name when available.
    func saveAppleAccount(
        identifier: String,
        email: String?,
        fullName: PersonNameComponents?,
        for user: User,
        context: ModelContext
    ) throws {
        user.accountProvider = "apple"
        user.appleUserIdentifier = identifier
        user.accountEmail = normalizedValue(email)
        user.signedInAt = Date()

        if let displayName = displayName(from: fullName) {
            user.name = displayName
        }

        try context.save()
    }

    /// Saves Google identity fields and derives a default username from email for placeholder profiles.
    func saveGoogleAccount(
        email: String,
        fullName: String?,
        profileImageData: Data?,
        for user: User,
        context: ModelContext
    ) throws {
        let normalizedEmail = normalizedValue(email)

        user.accountProvider = "google"
        user.appleUserIdentifier = nil
        user.accountEmail = normalizedEmail
        user.signedInAt = Date()

        if let displayName = normalizedValue(fullName) {
            user.name = displayName
        }

        if user.username == "placeholder" || user.username.isEmpty,
           let username = username(from: normalizedEmail) {
            user.username = username
        }

        if let profileImageData, !profileImageData.isEmpty {
            user.profileImage = profileImageData
        }

        try context.save()
    }

    /// Persists local profile edits while preserving account-provider fields.
    func saveProfile(
        name: String,
        username: String,
        selectedImage: UIImage?,
        for user: User,
        context: ModelContext
    ) throws {
        user.name = name
        user.username = username
        if let selectedImage {
            user.updateProfileImage(selectedImage)
        }
        try context.save()
    }

    /// Formats Apple name components into a non-empty display name.
    private func displayName(from fullName: PersonNameComponents?) -> String? {
        guard let fullName else { return nil }
        let formatter = PersonNameComponentsFormatter()
        let formattedName = formatter.string(from: fullName)
        return normalizedValue(formattedName)
    }

    /// Trims optional text values and treats blank strings as missing data.
    private func normalizedValue(_ value: String?) -> String? {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmedValue.isEmpty else {
            return nil
        }

        return trimmedValue
    }

    /// Derives a local username from the email's local part without storing any extra Google IDs.
    private func username(from email: String?) -> String? {
        guard let localPart = email?.split(separator: "@", maxSplits: 1).first else {
            return nil
        }

        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        let sanitized = localPart.unicodeScalars.map { scalar in
            allowedCharacters.contains(scalar) ? String(scalar) : "-"
        }.joined()

        return normalizedValue(sanitized)
    }
}
