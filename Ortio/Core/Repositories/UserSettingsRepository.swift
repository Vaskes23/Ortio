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
    var notificationsEnabled: Bool
    var soundEffectsEnabled: Bool
    var receiveEmailsEnabled: Bool
}

/// Persistence boundary for profile, theme, and simple settings preferences.
///
/// Settings view models use this protocol so tests can replace SwiftData and
/// `UserDefaults` writes with deterministic mocks.
@MainActor
protocol UserSettingsRepositoryProtocol {
    func loadPreferences() -> UserSettingsPreferences
    func savePreferences(_ preferences: UserSettingsPreferences)
    func loadOrCreateUser(from users: [User], context: ModelContext) throws -> User
    func saveTheme(_ theme: Theme, for user: User, context: ModelContext) throws
    func saveAppleAccount(
        identifier: String,
        email: String?,
        fullName: PersonNameComponents?,
        for user: User,
        context: ModelContext
    ) throws
    func saveGoogleAccount(
        email: String,
        fullName: String?,
        profileImageData: Data?,
        for user: User,
        context: ModelContext
    ) throws
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
    private enum Keys {
        static let notificationsEnabled = "notificationsEnabled"
        static let soundEffectsEnabled = "soundEffectsEnabled"
        static let receiveEmailsEnabled = "receiveEmailsEnabled"
    }

    nonisolated(unsafe) private let userDefaults: UserDefaults

    nonisolated init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadPreferences() -> UserSettingsPreferences {
        UserSettingsPreferences(
            notificationsEnabled: userDefaults.bool(forKey: Keys.notificationsEnabled),
            soundEffectsEnabled: userDefaults.bool(forKey: Keys.soundEffectsEnabled),
            receiveEmailsEnabled: userDefaults.bool(forKey: Keys.receiveEmailsEnabled)
        )
    }

    func savePreferences(_ preferences: UserSettingsPreferences) {
        userDefaults.set(preferences.notificationsEnabled, forKey: Keys.notificationsEnabled)
        userDefaults.set(preferences.soundEffectsEnabled, forKey: Keys.soundEffectsEnabled)
        userDefaults.set(preferences.receiveEmailsEnabled, forKey: Keys.receiveEmailsEnabled)
    }

    func loadOrCreateUser(from users: [User], context: ModelContext) throws -> User {
        if let existingUser = users.first {
            return existingUser
        }

        let user = User()
        context.insert(user)
        try context.save()
        return user
    }

    func saveTheme(_ theme: Theme, for user: User, context: ModelContext) throws {
        user.theme = theme
        try context.save()
    }

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

    private func displayName(from fullName: PersonNameComponents?) -> String? {
        guard let fullName else { return nil }
        let formatter = PersonNameComponentsFormatter()
        let formattedName = formatter.string(from: fullName)
        return normalizedValue(formattedName)
    }

    private func normalizedValue(_ value: String?) -> String? {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmedValue.isEmpty else {
            return nil
        }

        return trimmedValue
    }

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
