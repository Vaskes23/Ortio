//
//  SwiftDataModelTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
import SwiftData
@testable import Ortio

final class SwiftDataModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: Models.self, User.self, configurations: config)
        modelContext = ModelContext(modelContainer)
    }

    override func tearDownWithError() throws {
        modelContext = nil
        modelContainer = nil
    }

    // MARK: - Models Tests
    
    func testModelsInitialization() {
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
        XCTAssertEqual(model.name, name)
        XCTAssertEqual(model.date, date)
        XCTAssertEqual(model.favorite, favorite)
        XCTAssertEqual(model.imported, imported)
        XCTAssertEqual(model.size, size)
        XCTAssertEqual(model.model, modelURL)
    }
    
    func testModelsUniqueConstraints() throws {
        // Arrange
        let url1 = URL(fileURLWithPath: "/path/to/model1.usdz")
        let url2 = URL(fileURLWithPath: "/path/to/model2.usdz")
        
        let model1 = Models(name: "Model 1", date: Date(), favorite: false, imported: true, size: 1024, model: url1)
        let model2 = Models(name: "Model 2", date: Date(), favorite: true, imported: false, size: 2048, model: url2)
        
        // Act
        modelContext.insert(model1)
        modelContext.insert(model2)
        
        // Assert
        XCTAssertNoThrow(try modelContext.save())
        
        let fetchDescriptor = FetchDescriptor<Models>()
        let savedModels = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(savedModels.count, 2)
    }
    
    func testModelsIdentifiable() {
        // Arrange
        let model = Models(name: "Test Model", date: Date(), favorite: false, imported: true, size: 1024, model: URL(fileURLWithPath: "/path/to/model.usdz"))
        
        // Act & Assert
        XCTAssertNotNil(model.id)
    }
    
    // MARK: - User Tests
    
    func testUserInitialization() {
        // Arrange
        let username = "testuser"
        let name = "Test User"
        let theme: Theme = .dark
        let profileImageData = Data([1, 2, 3, 4])

        // Act
        let user = User(username: username, name: name, theme: theme, profileImage: profileImageData)

        // Assert
        XCTAssertEqual(user.username, username)
        XCTAssertEqual(user.name, name)
        XCTAssertEqual(user.theme, theme)
        XCTAssertEqual(user.profileImage, profileImageData)
    }
    
    func testUserConvenienceInitializer() {
        // Act
        let user = User()
        
        // Assert
        XCTAssertEqual(user.username, "placeholder")
        XCTAssertEqual(user.name, "Placeholder User")
        XCTAssertEqual(user.theme, .light)
        XCTAssertEqual(user.profileImage, Data())
    }
    
    func testUserProfileUIImageWithValidData() {
        // Arrange
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // Minimal JPEG header
        let user = User(username: "test", name: "Test", theme: .light, profileImage: imageData)
        
        // Act
        let uiImage = user.profileUIImage
        
        // Assert
        // Note: This will be nil because the data is not a valid image, but we're testing the property
        XCTAssertNil(uiImage) // Invalid image data should return nil
    }
    
    func testUserProfileUIImageWithNilData() {
        // Arrange
        let user = User(username: "test", name: "Test", theme: .light, profileImage: nil)
        
        // Act
        let uiImage = user.profileUIImage
        
        // Assert
        XCTAssertNil(uiImage)
    }
    
    func testUserUpdateProfileImage() {
        // Arrange
        let user = User(username: "test", name: "Test", theme: .light, profileImage: nil)
        let testImage = createTestImage()
        
        // Act
        user.updateProfileImage(testImage)
        
        // Assert
        XCTAssertNotNil(user.profileImage)
        XCTAssertGreaterThan(user.profileImage?.count ?? 0, 0)
    }
    
    func testUserUniqueConstraints() throws {
        // Arrange
        let user1 = User(username: "user1", name: "User 1", theme: .light, profileImage: nil)
        let user2 = User(username: "user2", name: "User 2", theme: .dark, profileImage: nil)
        
        // Act
        modelContext.insert(user1)
        modelContext.insert(user2)
        
        // Assert
        XCTAssertNoThrow(try modelContext.save())
        
        let fetchDescriptor = FetchDescriptor<User>()
        let savedUsers = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(savedUsers.count, 2)
    }
    
    func testUserIdentifiable() {
        // Arrange
        let user = User(username: "test", name: "Test", theme: .light, profileImage: nil)
        
        // Act & Assert
        XCTAssertNotNil(user.username) // username is the unique identifier
    }
    
    // MARK: - SwiftData Operations Tests
    
    func testSaveAndFetchModels() throws {
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
        XCTAssertEqual(fetchedModels.count, 2)
        XCTAssertTrue(fetchedModels.contains { $0.name == "Model 1" })
        XCTAssertTrue(fetchedModels.contains { $0.name == "Model 2" })
    }
    
    func testSaveAndFetchUsers() throws {
        // Arrange
        let user1 = User(username: "user1", name: "User 1", theme: .light, profileImage: nil)
        let user2 = User(username: "user2", name: "User 2", theme: .dark, profileImage: nil)
        
        // Act
        modelContext.insert(user1)
        modelContext.insert(user2)
        try modelContext.save()
        
        let fetchDescriptor = FetchDescriptor<User>()
        let fetchedUsers = try modelContext.fetch(fetchDescriptor)
        
        // Assert
        XCTAssertEqual(fetchedUsers.count, 2)
        XCTAssertTrue(fetchedUsers.contains { $0.username == "user1" })
        XCTAssertTrue(fetchedUsers.contains { $0.username == "user2" })
    }
    
    func testDeleteModel() throws {
        // Arrange
        let model = Models(name: "Test Model", date: Date(), favorite: false, imported: true, size: 1024, model: URL(fileURLWithPath: "/path/to/model.usdz"))
        modelContext.insert(model)
        try modelContext.save()
        
        // Verify model exists
        let fetchDescriptor = FetchDescriptor<Models>()
        var fetchedModels = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedModels.count, 1)
        
        // Act
        modelContext.delete(model)
        try modelContext.save()
        
        // Assert
        fetchedModels = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedModels.count, 0)
    }
    
    func testDeleteUser() throws {
        // Arrange
        let user = User(username: "testuser", name: "Test User", theme: .light, profileImage: nil)
        modelContext.insert(user)
        try modelContext.save()
        
        // Verify user exists
        let fetchDescriptor = FetchDescriptor<User>()
        var fetchedUsers = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedUsers.count, 1)
        
        // Act
        modelContext.delete(user)
        try modelContext.save()
        
        // Assert
        fetchedUsers = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedUsers.count, 0)
    }
    
    func testUpdateModel() throws {
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
        XCTAssertEqual(fetchedModels.count, 1)
        XCTAssertEqual(fetchedModels.first?.name, "Updated Name")
        XCTAssertTrue(fetchedModels.first?.favorite ?? false)
    }
    
    func testUpdateUser() throws {
        // Arrange
        let user = User(username: "original", name: "Original Name", theme: .light, profileImage: nil)
        modelContext.insert(user)
        try modelContext.save()
        
        // Act
        user.name = "Updated Name"
        user.theme = .dark
        try modelContext.save()

        // Assert
        let fetchDescriptor = FetchDescriptor<User>()
        let fetchedUsers = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedUsers.count, 1)
        XCTAssertEqual(fetchedUsers.first?.name, "Updated Name")
        XCTAssertEqual(fetchedUsers.first?.theme, .dark)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()! // swiftlint:disable:this force_unwrapping
        UIGraphicsEndImageContext()
        return image
    }
}
