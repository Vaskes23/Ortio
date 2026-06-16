//
//  UserSettingsRepositoryTests.swift
//  OrtioTests
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

    func testSaveAppleAccountStoresMinimalIdentity() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: User.self, configurations: configuration)
        let context = ModelContext(container)
        let user = User(username: "placeholder", name: "Placeholder User", theme: .light, profileImage: nil)
        var fullName = PersonNameComponents()
        fullName.givenName = "Ada"
        fullName.familyName = "Lovelace"
        context.insert(user)
        try context.save()

        try repository.saveAppleAccount(
            identifier: "apple-stable-user-id",
            email: " ada@example.com ",
            fullName: fullName,
            for: user,
            context: context
        )

        XCTAssertTrue(user.isSignedInWithApple)
        XCTAssertEqual(user.accountProvider, "apple")
        XCTAssertEqual(user.appleUserIdentifier, "apple-stable-user-id")
        XCTAssertEqual(user.accountEmail, "ada@example.com")
        XCTAssertEqual(user.name, "Ada Lovelace")
        XCTAssertNotNil(user.signedInAt)
    }

    func testSaveGoogleAccountStoresCompactProfile() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: User.self, configurations: configuration)
        let context = ModelContext(container)
        let avatarData = Data([0x01, 0x02, 0x03])
        let user = User(username: "placeholder", name: "Placeholder User", theme: .light, profileImage: nil)
        context.insert(user)
        try context.save()

        try repository.saveGoogleAccount(
            email: " ada.lovelace@example.com ",
            fullName: " Ada Lovelace ",
            profileImageData: avatarData,
            for: user,
            context: context
        )

        XCTAssertTrue(user.isAuthenticated)
        XCTAssertTrue(user.isSignedInWithGoogle)
        XCTAssertFalse(user.isSignedInWithApple)
        XCTAssertEqual(user.accountProvider, "google")
        XCTAssertNil(user.appleUserIdentifier)
        XCTAssertEqual(user.accountEmail, "ada.lovelace@example.com")
        XCTAssertEqual(user.username, "ada.lovelace")
        XCTAssertEqual(user.name, "Ada Lovelace")
        XCTAssertEqual(user.profileImage, avatarData)
        XCTAssertNotNil(user.signedInAt)
    }
}
