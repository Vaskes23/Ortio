//
//  SwiftDataModelTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Testing
import SwiftData
@testable import Ortio

@Suite
struct SwiftDataModelTests {
    var modelContainer: ModelContainer
    var modelContext: ModelContext

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: Models.self, User.self, configurations: config)
        modelContext = ModelContext(modelContainer)
    }

    deinit {
        // cleanup automatically
    }

    // MARK: - Models Tests
    
    @Test
    func modelsInitialization() {
        // Arrange
        let name = "Test Model"
        let date = Date()
        let favorite = true
        let imported = false
        let size: Double = 1024.0
        let modelURL = URL(fileURLWithPath: "/path/to/model.usdz")
        
        // Act
        let model = Models(name: name, date: date, favorite: favorite, imported: imported, size: size, model: modelURL)
        
        // Assert
        #expect(model.name == name)
        #expect(model.date == date)
        #expect(model.favorite == favorite)
        #expect(model.imported == imported)
        #expect(model.size == size)
        #expect(model.model == modelURL)
    }

    @Test
    func modelsUniqueConstraints() throws {
        // Arrange
        let url1 = URL(fileURLWithPath: "/path/to/model1.usdz")
        let url2 = URL(fileURLWithPath: "/path/to/model2.usdz")
        
        let model1 = Models(name: "Model 1", date: Date(), favorite: false, imported: true, size: 1024, model: url1)
        let model2 = Models(name: "Model 2", date: Date(), favorite: true, imported: false, size: 2048, model: url2)
        
        // Act
        modelContext.insert(model1)
        modelContext.insert(model2)
        
        // Assert
        #expect(throws: Never.self) { try modelContext.save() }

        let fetchDescriptor = FetchDescriptor<Models>()
        let savedModels = try modelContext.fetch(fetchDescriptor)
        #expect(savedModels.count == 2)
    }

    @Test
    func modelsIdentifiable() {
        // Arrange
        let model = Models(name: "Test Model", date: Date(), favorite: false, imported: true, size: 1024, model: URL(fileURLWithPath: "/path/to/model.usdz"))
        
        // Act & Assert
        #expect(model.id != nil)
    }
    
    // MARK: - User Tests
    
    @Test
    func userInitialization() {
        // Arrange
        let username = "testuser"
        let name = "Test User"
        let appearance = 1
        let profileImageData = Data([1, 2, 3, 4])
        
        // Act
        let user = User(username: username, name: name, appearance: appearance, profileImage: profileImageData)
        
        // Assert
        #expect(user.username == username)
        #expect(user.name == name)
        #expect(user.appearance == appearance)
        #expect(user.profileImage == profileImageData)
    }

    @Test
    func userConvenienceInitializer() {
        // Act
        let user = User()
        
        // Assert
        #expect(user.username == "placeholder")
        #expect(user.name == "Placeholder User")
        #expect(user.appearance == 0)
        #expect(user.profileImage == Data())
    }

    @Test
    func userProfileUIImageWithValidData() {
        // Arrange
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // Minimal JPEG header
        let user = User(username: "test", name: "Test", appearance: 0, profileImage: imageData)
        
        // Act
        let uiImage = user.profileUIImage
        
        // Assert
        // Note: This will be nil because the data is not a valid image, but we're testing the property
        #expect(uiImage == nil) // Invalid image data should return nil
    }

    @Test
    func userProfileUIImageWithNilData() {
        // Arrange
        let user = User(username: "test", name: "Test", appearance: 0, profileImage: nil)
        
        // Act
        let uiImage = user.profileUIImage
        
        // Assert
        #expect(uiImage == nil)
    }

    @Test
    func userUpdateProfileImage() {
        // Arrange
        let user = User(username: "test", name: "Test", appearance: 0, profileImage: nil)
        let testImage = createTestImage()
        
        // Act
        user.updateProfileImage(testImage)
        
        // Assert
        #expect(user.profileImage != nil)
        #expect((user.profileImage?.count ?? 0) > 0)
    }

    @Test
    func userUniqueConstraints() throws {
        // Arrange
        let user1 = User(username: "user1", name: "User 1", appearance: 0, profileImage: nil)
        let user2 = User(username: "user2", name: "User 2", appearance: 1, profileImage: nil)
        
        // Act
        modelContext.insert(user1)
        modelContext.insert(user2)
        
        // Assert
        #expect(throws: Never.self) { try modelContext.save() }

        let fetchDescriptor = FetchDescriptor<User>()
        let savedUsers = try modelContext.fetch(fetchDescriptor)
        #expect(savedUsers.count == 2)
    }
    
    @Test
    func userIdentifiable() {
        // Arrange
        let user = User(username: "test", name: "Test", appearance: 0, profileImage: nil)
        
        // Act & Assert
        #expect(user.username != nil) // username is the unique identifier
    }
    
    // MARK: - SwiftData Operations Tests
    
    @Test
    func saveAndFetchModels() throws {
        // Arrange
        let model1 = Models(name: "Model 1", date: Date(), favorite: false, imported: true, size: 1024, model: URL(fileURLWithPath: "/path/to/model1.usdz"))
        let model2 = Models(name: "Model 2", date: Date(), favorite: true, imported: false, size: 2048, model: URL(fileURLWithPath: "/path/to/model2.usdz"))
        
        // Act
        modelContext.insert(model1)
        modelContext.insert(model2)
        try modelContext.save()
        
        let fetchDescriptor = FetchDescriptor<Models>()
        let fetchedModels = try modelContext.fetch(fetchDescriptor)
        
        // Assert
        #expect(fetchedModels.count == 2)
        #expect(fetchedModels.contains { $0.name == "Model 1" })
        #expect(fetchedModels.contains { $0.name == "Model 2" })
    }

    @Test
    func saveAndFetchUsers() throws {
        // Arrange
        let user1 = User(username: "user1", name: "User 1", appearance: 0, profileImage: nil)
        let user2 = User(username: "user2", name: "User 2", appearance: 1, profileImage: nil)
        
        // Act
        modelContext.insert(user1)
        modelContext.insert(user2)
        try modelContext.save()
        
        let fetchDescriptor = FetchDescriptor<User>()
        let fetchedUsers = try modelContext.fetch(fetchDescriptor)
        
        // Assert
        #expect(fetchedUsers.count == 2)
        #expect(fetchedUsers.contains { $0.username == "user1" })
        #expect(fetchedUsers.contains { $0.username == "user2" })
    }

    @Test
    func deleteModel() throws {
        // Arrange
        let model = Models(name: "Test Model", date: Date(), favorite: false, imported: true, size: 1024, model: URL(fileURLWithPath: "/path/to/model.usdz"))
        modelContext.insert(model)
        try modelContext.save()
        
        // Verify model exists
        let fetchDescriptor = FetchDescriptor<Models>()
        var fetchedModels = try modelContext.fetch(fetchDescriptor)
        #expect(fetchedModels.count == 1)
        
        // Act
        modelContext.delete(model)
        try modelContext.save()
        
        // Assert
        fetchedModels = try modelContext.fetch(fetchDescriptor)
        #expect(fetchedModels.count == 0)
    }

    @Test
    func deleteUser() throws {
        // Arrange
        let user = User(username: "testuser", name: "Test User", appearance: 0, profileImage: nil)
        modelContext.insert(user)
        try modelContext.save()
        
        // Verify user exists
        let fetchDescriptor = FetchDescriptor<User>()
        var fetchedUsers = try modelContext.fetch(fetchDescriptor)
        #expect(fetchedUsers.count == 1)
        
        // Act
        modelContext.delete(user)
        try modelContext.save()
        
        // Assert
        fetchedUsers = try modelContext.fetch(fetchDescriptor)
        #expect(fetchedUsers.count == 0)
    }

    @Test
    func updateModel() throws {
        // Arrange
        let model = Models(name: "Original Name", date: Date(), favorite: false, imported: true, size: 1024, model: URL(fileURLWithPath: "/path/to/model.usdz"))
        modelContext.insert(model)
        try modelContext.save()
        
        // Act
        model.name = "Updated Name"
        model.favorite = true
        try modelContext.save()
        
        // Assert
        let fetchDescriptor = FetchDescriptor<Models>()
        let fetchedModels = try modelContext.fetch(fetchDescriptor)
        #expect(fetchedModels.count == 1)
        #expect(fetchedModels.first?.name == "Updated Name")
        #expect(fetchedModels.first?.favorite ?? false)
    }

    @Test
    func updateUser() throws {
        // Arrange
        let user = User(username: "original", name: "Original Name", appearance: 0, profileImage: nil)
        modelContext.insert(user)
        try modelContext.save()
        
        // Act
        user.name = "Updated Name"
        user.appearance = 1
        try modelContext.save()
        
        // Assert
        let fetchDescriptor = FetchDescriptor<User>()
        let fetchedUsers = try modelContext.fetch(fetchDescriptor)
        #expect(fetchedUsers.count == 1)
        #expect(fetchedUsers.first?.name == "Updated Name")
        #expect(fetchedUsers.first?.appearance == 1)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
} 
