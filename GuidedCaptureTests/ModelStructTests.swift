//
//  ModelStructTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Testing
@testable import Ortio

@Suite
struct ModelStructTests {

    // MARK: - ModelsModel Tests

    @Test
    func modelsModelIdentifiableCaptureURLInitialization() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/model.usdz")
        
        // Act
        let identifiableURL = ModelsModel.IdentifiableCaptureURL(url: url)
        
        // Assert
        #expect(identifiableURL.url == url)
        #expect(identifiableURL.id != nil)
    }

    @Test
    func modelsModelIdentifiableCaptureURLIdentifiable() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/model.usdz")
        
        // Act
        let identifiableURL = ModelsModel.IdentifiableCaptureURL(url: url)
        
        // Assert
        #expect(identifiableURL.id != nil)
        #expect(identifiableURL.id is UUID)
    }

    @Test
    func modelsModelIdentifiableCaptureURLUniqueIds() {
        // Arrange
        let url1 = URL(fileURLWithPath: "/path/to/model1.usdz")
        let url2 = URL(fileURLWithPath: "/path/to/model2.usdz")
        
        // Act
        let identifiableURL1 = ModelsModel.IdentifiableCaptureURL(url: url1)
        let identifiableURL2 = ModelsModel.IdentifiableCaptureURL(url: url2)
        
        // Assert
        #expect(identifiableURL1.id != identifiableURL2.id)
        #expect(identifiableURL1.url == url1)
        #expect(identifiableURL2.url == url2)
    }

    @Test
    func modelsModelIdentifiableCaptureURLWithDifferentURLs() {
        // Arrange
        let urls = [
            URL(fileURLWithPath: "/path/to/model1.usdz"),
            URL(fileURLWithPath: "/path/to/model2.usdz"),
            URL(fileURLWithPath: "/path/to/model3.usdz")
        ]
        
        // Act
        let identifiableURLs = urls.map { ModelsModel.IdentifiableCaptureURL(url: $0) }
        
        // Assert
        #expect(identifiableURLs.count == 3)
        for (index, identifiableURL) in identifiableURLs.enumerated() {
            #expect(identifiableURL.url == urls[index])
        }

        // All IDs should be unique
        let ids = identifiableURLs.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }
    
    // MARK: - ImportModel Tests
    
    @Test
    func importModelIdentifiableURLInitialization() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/import.usdz")
        
        // Act
        let identifiableURL = ImportModel.IdentifiableURL(url: url)
        
        // Assert
        #expect(identifiableURL.url == url)
        #expect(identifiableURL.id != nil)
    }

    @Test
    func importModelIdentifiableURLIdentifiable() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/import.usdz")
        
        // Act
        let identifiableURL = ImportModel.IdentifiableURL(url: url)
        
        // Assert
        #expect(identifiableURL.id != nil)
        #expect(identifiableURL.id is UUID)
    }

    @Test
    func importModelIdentifiableURLUniqueIds() {
        // Arrange
        let url1 = URL(fileURLWithPath: "/path/to/import1.usdz")
        let url2 = URL(fileURLWithPath: "/path/to/import2.usdz")
        
        // Act
        let identifiableURL1 = ImportModel.IdentifiableURL(url: url1)
        let identifiableURL2 = ImportModel.IdentifiableURL(url: url2)
        
        // Assert
        #expect(identifiableURL1.id != identifiableURL2.id)
        #expect(identifiableURL1.url == url1)
        #expect(identifiableURL2.url == url2)
    }

    @Test
    func importModelIdentifiableURLWithDifferentURLs() {
        // Arrange
        let urls = [
            URL(fileURLWithPath: "/path/to/import1.usdz"),
            URL(fileURLWithPath: "/path/to/import2.usdz"),
            URL(fileURLWithPath: "/path/to/import3.usdz")
        ]
        
        // Act
        let identifiableURLs = urls.map { ImportModel.IdentifiableURL(url: $0) }
        
        // Assert
        #expect(identifiableURLs.count == 3)
        for (index, identifiableURL) in identifiableURLs.enumerated() {
            #expect(identifiableURL.url == urls[index])
        }

        // All IDs should be unique
        let ids = identifiableURLs.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }
    
    // MARK: - Comparison Tests
    
    @Test
    func modelsModelIdentifiableCaptureURLEquality() {
        // Arrange
        let url1 = URL(fileURLWithPath: "/path/to/model.usdz")
        let url2 = URL(fileURLWithPath: "/path/to/model.usdz")
        
        // Act
        let identifiableURL1 = ModelsModel.IdentifiableCaptureURL(url: url1)
        let identifiableURL2 = ModelsModel.IdentifiableCaptureURL(url: url2)
        
        // Assert
        #expect(identifiableURL1.url == identifiableURL2.url)
        // IDs should be different even with same URL
        #expect(identifiableURL1.id != identifiableURL2.id)
    }

    @Test
    func importModelIdentifiableURLEquality() {
        // Arrange
        let url1 = URL(fileURLWithPath: "/path/to/import.usdz")
        let url2 = URL(fileURLWithPath: "/path/to/import.usdz")
        
        // Act
        let identifiableURL1 = ImportModel.IdentifiableURL(url: url1)
        let identifiableURL2 = ImportModel.IdentifiableURL(url: url2)
        
        // Assert
        #expect(identifiableURL1.url == identifiableURL2.url)
        // IDs should be different even with same URL
        #expect(identifiableURL1.id != identifiableURL2.id)
    }
    
    // MARK: - URL Path Extension Tests
    
    @Test
    func modelsModelIdentifiableCaptureURLWithDifferentExtensions() {
        // Arrange
        let urls = [
            URL(fileURLWithPath: "/path/to/model.usdz"),
            URL(fileURLWithPath: "/path/to/model.usd"),
            URL(fileURLWithPath: "/path/to/model.reality")
        ]
        
        // Act
        let identifiableURLs = urls.map { ModelsModel.IdentifiableCaptureURL(url: $0) }
        
        // Assert
        #expect(identifiableURLs.count == 3)
        #expect(identifiableURLs[0].url.pathExtension == "usdz")
        #expect(identifiableURLs[1].url.pathExtension == "usd")
        #expect(identifiableURLs[2].url.pathExtension == "reality")
    }

    @Test
    func importModelIdentifiableURLWithDifferentExtensions() {
        // Arrange
        let urls = [
            URL(fileURLWithPath: "/path/to/import.usdz"),
            URL(fileURLWithPath: "/path/to/import.usd"),
            URL(fileURLWithPath: "/path/to/import.reality")
        ]
        
        // Act
        let identifiableURLs = urls.map { ImportModel.IdentifiableURL(url: $0) }
        
        // Assert
        #expect(identifiableURLs.count == 3)
        #expect(identifiableURLs[0].url.pathExtension == "usdz")
        #expect(identifiableURLs[1].url.pathExtension == "usd")
        #expect(identifiableURLs[2].url.pathExtension == "reality")
    }
    
    // MARK: - URL Last Path Component Tests
    
    @Test
    func modelsModelIdentifiableCaptureURLLastPathComponent() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/folder/model.usdz")
        
        // Act
        let identifiableURL = ModelsModel.IdentifiableCaptureURL(url: url)
        
        // Assert
        #expect(identifiableURL.url.lastPathComponent == "model.usdz")
    }

    @Test
    func importModelIdentifiableURLLastPathComponent() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/folder/import.usdz")
        
        // Act
        let identifiableURL = ImportModel.IdentifiableURL(url: url)
        
        // Assert
        #expect(identifiableURL.url.lastPathComponent == "import.usdz")
    }
    
    // MARK: - URL Deleting Path Extension Tests
    
    @Test
    func modelsModelIdentifiableCaptureURLDeletingPathExtension() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/model.usdz")
        
        // Act
        let identifiableURL = ModelsModel.IdentifiableCaptureURL(url: url)
        let urlWithoutExtension = identifiableURL.url.deletingPathExtension()
        
        // Assert
        #expect(urlWithoutExtension.lastPathComponent == "model")
    }

    @Test
    func importModelIdentifiableURLDeletingPathExtension() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/import.usdz")
        
        // Act
        let identifiableURL = ImportModel.IdentifiableURL(url: url)
        let urlWithoutExtension = identifiableURL.url.deletingPathExtension()
        
        // Assert
        #expect(urlWithoutExtension.lastPathComponent == "import")
    }
}
