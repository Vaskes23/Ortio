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
}
