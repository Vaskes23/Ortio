//
//  UserSettingsRepository.swift
//  GuidedCapture
//
//  Created by OpenAI on 08.04.2026.
//

import Foundation
import SwiftData
import UIKit

struct UserSettingsPreferences: Equatable {
    var notificationsEnabled: Bool
    var soundEffectsEnabled: Bool
    var receiveEmailsEnabled: Bool
}

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

@MainActor
final class UserSettingsRepository: UserSettingsRepositoryProtocol {
    private enum Keys {
        static let notificationsEnabled = "notificationsEnabled"
        static let soundEffectsEnabled = "soundEffectsEnabled"
        static let receiveEmailsEnabled = "receiveEmailsEnabled"
    }

    private let userDefaults: UserDefaults

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
