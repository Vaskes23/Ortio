import Testing
import Foundation
import SwiftData
@testable import Ortio

@Suite("Settings View Model")
struct SettingsViewModelTests {
    @Test
    func initReadsBooleanFlagsFromUserDefaults() {
        clearUserDefaults()
        defer { clearUserDefaults() }

        UserDefaults.standard.set(true, forKey: "notificationsEnabled")
        UserDefaults.standard.set(false, forKey: "soundEffectsEnabled")
        UserDefaults.standard.set(true, forKey: "receiveEmailsEnabled")

        let viewModel = SettingsViewModel()

        #expect(viewModel.notificationsEnabled)
        #expect(!viewModel.soundEffectsEnabled)
        #expect(viewModel.receiveEmailsEnabled)
    }

    @Test
    func updatingFlagsPersistsToUserDefaults() {
        clearUserDefaults()
        defer { clearUserDefaults() }

        let viewModel = SettingsViewModel()

        viewModel.notificationsEnabled = true
        viewModel.soundEffectsEnabled = true
        viewModel.receiveEmailsEnabled = false

        #expect(UserDefaults.standard.bool(forKey: "notificationsEnabled"))
        #expect(UserDefaults.standard.bool(forKey: "soundEffectsEnabled"))
        #expect(!UserDefaults.standard.bool(forKey: "receiveEmailsEnabled"))
    }

    @Test
    func loadUserUsesExistingUser() throws {
        clearUserDefaults()
        defer { clearUserDefaults() }

        let (modelContainer, modelContext) = try makeInMemoryContext()
        _ = modelContainer
        let existingUser = User(username: "alice", name: "Alice", theme: .dark, profileImage: nil)
        let viewModel = SettingsViewModel()

        viewModel.loadUser(from: [existingUser], context: modelContext)

        #expect(viewModel.user.username == "alice")
        #expect(viewModel.name == "Alice")
        #expect(viewModel.selectedTheme == .dark)
    }

    @Test
    func loadUserCreatesDefaultUserWhenMissing() throws {
        clearUserDefaults()
        defer { clearUserDefaults() }

        let (modelContainer, modelContext) = try makeInMemoryContext()
        _ = modelContainer
        let viewModel = SettingsViewModel()

        viewModel.loadUser(from: [], context: modelContext)

        let users = try modelContext.fetch(FetchDescriptor<User>())
        #expect(users.count == 1)
        #expect(viewModel.name == "Placeholder User")
        #expect(viewModel.selectedTheme == .light)
    }

    @Test
    func saveThemePersistsOnCurrentUser() throws {
        clearUserDefaults()
        defer { clearUserDefaults() }

        let (modelContainer, modelContext) = try makeInMemoryContext()
        _ = modelContainer
        let user = User(username: "alice", name: "Alice", theme: .light, profileImage: nil)
        modelContext.insert(user)
        try modelContext.save()

        let viewModel = SettingsViewModel()
        viewModel.user = user
        viewModel.selectedTheme = .dark

        viewModel.saveTheme(context: modelContext)

        let users = try modelContext.fetch(FetchDescriptor<User>())
        #expect(users.first?.theme == .dark)
        #expect(viewModel.errorMessage == nil)
    }

    private func makeInMemoryContext() throws -> (ModelContainer, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, configurations: config)
        let modelContext = ModelContext(modelContainer)
        return (modelContainer, modelContext)
    }

    private func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
        UserDefaults.standard.removeObject(forKey: "soundEffectsEnabled")
        UserDefaults.standard.removeObject(forKey: "receiveEmailsEnabled")
    }
}
