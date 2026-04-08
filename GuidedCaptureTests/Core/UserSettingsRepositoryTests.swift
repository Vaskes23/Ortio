//
//  UserSettingsRepositoryTests.swift
//  GuidedCaptureTests
//
//  Created by OpenAI on 08.04.2026.
//

import XCTest
import SwiftData
@testable import Ortio

@MainActor
final class UserSettingsRepositoryTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var repository: UserSettingsRepository!

    override func setUpWithError() throws {
        suiteName = "UserSettingsRepositoryTests-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        repository = UserSettingsRepository(userDefaults: userDefaults)
    }

    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: suiteName)
        suiteName = nil
        userDefaults = nil
        repository = nil
    }

    func testLoadAndSavePreferencesRoundTrip() {
        let preferences = UserSettingsPreferences(
            notificationsEnabled: true,
            soundEffectsEnabled: false,
            receiveEmailsEnabled: true
        )

        repository.savePreferences(preferences)

        XCTAssertEqual(repository.loadPreferences(), preferences)
    }

    func testLoadOrCreateUserCreatesDefaultUser() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: User.self, configurations: configuration)
        let context = ModelContext(container)

        let user = try repository.loadOrCreateUser(from: [], context: context)

        XCTAssertEqual(user.name, "Placeholder User")
        XCTAssertEqual(try context.fetch(FetchDescriptor<User>()).count, 1)
    }

    func testSaveThemePersistsTheme() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: User.self, configurations: configuration)
        let context = ModelContext(container)
        let user = User(username: "alice", name: "Alice", theme: .light, profileImage: nil)
        context.insert(user)
        try context.save()

        try repository.saveTheme(.dark, for: user, context: context)

        XCTAssertEqual(user.theme, .dark)
    }
}
