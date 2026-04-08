//
//  SettingsViewModelTests.swift
//  GuidedCaptureTests
//
//  Created by OpenAI on 08.04.2026.
//

import XCTest
import SwiftData
@testable import Ortio

@MainActor
final class SettingsViewModelTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var repository: UserSettingsRepository!
    private var viewModel: SettingsViewModel!
    private var themeController: ThemeController!

    override func setUpWithError() throws {
        suiteName = "SettingsViewModelTests-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
        repository = UserSettingsRepository(userDefaults: userDefaults)
        viewModel = SettingsViewModel(repository: repository)
        themeController = ThemeController()
    }

    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: suiteName)
        suiteName = nil
        userDefaults = nil
        repository = nil
        viewModel = nil
        themeController = nil
    }

    func testInitReadsBooleanFlagsFromUserDefaults() throws {
        userDefaults.set(true, forKey: "notificationsEnabled")
        userDefaults.set(false, forKey: "soundEffectsEnabled")
        userDefaults.set(true, forKey: "receiveEmailsEnabled")

        let reloadedViewModel = SettingsViewModel(repository: UserSettingsRepository(userDefaults: userDefaults))

        XCTAssertTrue(reloadedViewModel.notificationsEnabled)
        XCTAssertFalse(reloadedViewModel.soundEffectsEnabled)
        XCTAssertTrue(reloadedViewModel.receiveEmailsEnabled)
    }

    func testUpdatingFlagsPersistsToUserDefaults() {
        viewModel.notificationsEnabled = true
        viewModel.soundEffectsEnabled = true
        viewModel.receiveEmailsEnabled = false

        XCTAssertTrue(userDefaults.bool(forKey: "notificationsEnabled"))
        XCTAssertTrue(userDefaults.bool(forKey: "soundEffectsEnabled"))
        XCTAssertFalse(userDefaults.bool(forKey: "receiveEmailsEnabled"))
    }

    func testLoadUserUsesExistingUserAndAppliesTheme() throws {
        let (_, context) = try makeInMemoryContext()
        let existingUser = User(username: "alice", name: "Alice", theme: .dark, profileImage: nil)

        viewModel.loadUser(from: [existingUser], context: context, themeController: themeController)

        XCTAssertEqual(viewModel.user.username, "alice")
        XCTAssertEqual(viewModel.name, "Alice")
        XCTAssertEqual(themeController.selectedTheme, .dark)
    }

    func testLoadUserCreatesDefaultUserWhenMissing() throws {
        let (_, context) = try makeInMemoryContext()

        viewModel.loadUser(from: [], context: context, themeController: themeController)

        let users = try context.fetch(FetchDescriptor<User>())
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(viewModel.name, "Placeholder User")
        XCTAssertEqual(themeController.selectedTheme, .light)
    }

    func testSaveThemePersistsControllerSelection() throws {
        let (_, context) = try makeInMemoryContext()
        let user = User(username: "alice", name: "Alice", theme: .light, profileImage: nil)
        context.insert(user)
        try context.save()
        viewModel.user = user
        themeController.apply(theme: .dark)

        viewModel.saveTheme(using: themeController, context: context)

        let users = try context.fetch(FetchDescriptor<User>())
        XCTAssertEqual(users.first?.theme, .dark)
        XCTAssertNil(viewModel.errorMessage)
    }

    private func makeInMemoryContext() throws -> (ModelContainer, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, configurations: config)
        let modelContext = ModelContext(modelContainer)
        return (modelContainer, modelContext)
    }
}
