//
//  ModelStructTests.swift
//  OrtioTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
@testable import Ortio

final class ModelStructTests: XCTestCase {

    // MARK: - ModelsModel Tests
    
    func testModelsModelIdentifiableCaptureURLInitialization() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/model.usdz")
        
        // Act
        let identifiableURL = ModelsModel.IdentifiableCaptureURL(url: url)
        
        // Assert
        XCTAssertEqual(identifiableURL.url, url)
        XCTAssertNotNil(identifiableURL.id)
    }
    
    func testModelsModelIdentifiableCaptureURLIdentifiable() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/model.usdz")
        
        // Act
        let identifiableURL = ModelsModel.IdentifiableCaptureURL(url: url)
        
        // Assert
        XCTAssertEqual(identifiableURL.id, url.standardizedFileURL.path)
    }
    
    func testModelsModelIdentifiableCaptureURLUniqueIds() {
        // Arrange
        let url1 = URL(fileURLWithPath: "/path/to/model1.usdz")
        let url2 = URL(fileURLWithPath: "/path/to/model2.usdz")
        
        // Act
        let identifiableURL1 = ModelsModel.IdentifiableCaptureURL(url: url1)
        let identifiableURL2 = ModelsModel.IdentifiableCaptureURL(url: url2)
        
        // Assert
        XCTAssertNotEqual(identifiableURL1.id, identifiableURL2.id)
        XCTAssertEqual(identifiableURL1.url, url1)
        XCTAssertEqual(identifiableURL2.url, url2)
    }
    
    func testModelsModelIdentifiableCaptureURLWithDifferentURLs() {
        // Arrange
        let urls = [
            URL(fileURLWithPath: "/path/to/model1.usdz"),
            URL(fileURLWithPath: "/path/to/model2.usdz"),
            URL(fileURLWithPath: "/path/to/model3.usdz")
        ]
        
        // Act
        let identifiableURLs = urls.map { ModelsModel.IdentifiableCaptureURL(url: $0) }
        
        // Assert
        XCTAssertEqual(identifiableURLs.count, 3)
        for (index, identifiableURL) in identifiableURLs.enumerated() {
            XCTAssertEqual(identifiableURL.url, urls[index])
        }
        
        // All IDs should be unique
        let ids = identifiableURLs.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count)
    }
    
    // MARK: - ImportModel Tests
    
    func testImportModelIdentifiableURLInitialization() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/import.usdz")
        
        // Act
        let identifiableURL = ImportModel.IdentifiableURL(url: url)
        
        // Assert
        XCTAssertEqual(identifiableURL.url, url)
        XCTAssertNotNil(identifiableURL.id)
    }
    
    func testImportModelIdentifiableURLIdentifiable() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/import.usdz")
        
        // Act
        let identifiableURL = ImportModel.IdentifiableURL(url: url)

        // Assert
        XCTAssertNotEqual(identifiableURL.id.uuidString, "")
    }
    
    func testImportModelIdentifiableURLUniqueIds() {
        // Arrange
        let url1 = URL(fileURLWithPath: "/path/to/import1.usdz")
        let url2 = URL(fileURLWithPath: "/path/to/import2.usdz")
        
        // Act
        let identifiableURL1 = ImportModel.IdentifiableURL(url: url1)
        let identifiableURL2 = ImportModel.IdentifiableURL(url: url2)
        
        // Assert
        XCTAssertNotEqual(identifiableURL1.id, identifiableURL2.id)
        XCTAssertEqual(identifiableURL1.url, url1)
        XCTAssertEqual(identifiableURL2.url, url2)
    }
    
    func testImportModelIdentifiableURLWithDifferentURLs() {
        // Arrange
        let urls = [
            URL(fileURLWithPath: "/path/to/import1.usdz"),
            URL(fileURLWithPath: "/path/to/import2.usdz"),
            URL(fileURLWithPath: "/path/to/import3.usdz")
        ]
        
        // Act
        let identifiableURLs = urls.map { ImportModel.IdentifiableURL(url: $0) }
        
        // Assert
        XCTAssertEqual(identifiableURLs.count, 3)
        for (index, identifiableURL) in identifiableURLs.enumerated() {
            XCTAssertEqual(identifiableURL.url, urls[index])
        }
        
        // All IDs should be unique
        let ids = identifiableURLs.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count)
    }
    
    // MARK: - Comparison Tests
    
    func testModelsModelIdentifiableCaptureURLEquality() {
        // Arrange
        let url1 = URL(fileURLWithPath: "/path/to/model.usdz")
        let url2 = URL(fileURLWithPath: "/path/to/model.usdz")
        
        // Act
        let identifiableURL1 = ModelsModel.IdentifiableCaptureURL(url: url1)
        let identifiableURL2 = ModelsModel.IdentifiableCaptureURL(url: url2)
        
        // Assert
        XCTAssertEqual(identifiableURL1.url, identifiableURL2.url)
        // IDs are URL-stable so SwiftUI lists preserve row identity across refreshes.
        XCTAssertEqual(identifiableURL1.id, identifiableURL2.id)
    }
    
    func testImportModelIdentifiableURLEquality() {
        // Arrange
        let url1 = URL(fileURLWithPath: "/path/to/import.usdz")
        let url2 = URL(fileURLWithPath: "/path/to/import.usdz")
        
        // Act
        let identifiableURL1 = ImportModel.IdentifiableURL(url: url1)
        let identifiableURL2 = ImportModel.IdentifiableURL(url: url2)
        
        // Assert
        XCTAssertEqual(identifiableURL1.url, identifiableURL2.url)
        // IDs should be different even with same URL
        XCTAssertNotEqual(identifiableURL1.id, identifiableURL2.id)
    }
    
    // MARK: - URL Path Extension Tests
    
    func testModelsModelIdentifiableCaptureURLWithDifferentExtensions() {
        // Arrange
        let urls = [
            URL(fileURLWithPath: "/path/to/model.usdz"),
            URL(fileURLWithPath: "/path/to/model.usd"),
            URL(fileURLWithPath: "/path/to/model.reality")
        ]
        
        // Act
        let identifiableURLs = urls.map { ModelsModel.IdentifiableCaptureURL(url: $0) }
        
        // Assert
        XCTAssertEqual(identifiableURLs.count, 3)
        XCTAssertEqual(identifiableURLs[0].url.pathExtension, "usdz")
        XCTAssertEqual(identifiableURLs[1].url.pathExtension, "usd")
        XCTAssertEqual(identifiableURLs[2].url.pathExtension, "reality")
    }
    
    func testImportModelIdentifiableURLWithDifferentExtensions() {
        // Arrange
        let urls = [
            URL(fileURLWithPath: "/path/to/import.usdz"),
            URL(fileURLWithPath: "/path/to/import.usd"),
            URL(fileURLWithPath: "/path/to/import.reality")
        ]
        
        // Act
        let identifiableURLs = urls.map { ImportModel.IdentifiableURL(url: $0) }
        
        // Assert
        XCTAssertEqual(identifiableURLs.count, 3)
        XCTAssertEqual(identifiableURLs[0].url.pathExtension, "usdz")
        XCTAssertEqual(identifiableURLs[1].url.pathExtension, "usd")
        XCTAssertEqual(identifiableURLs[2].url.pathExtension, "reality")
    }
    
    // MARK: - URL Last Path Component Tests
    
    func testModelsModelIdentifiableCaptureURLLastPathComponent() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/folder/model.usdz")
        
        // Act
        let identifiableURL = ModelsModel.IdentifiableCaptureURL(url: url)
        
        // Assert
        XCTAssertEqual(identifiableURL.url.lastPathComponent, "model.usdz")
    }
    
    func testImportModelIdentifiableURLLastPathComponent() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/folder/import.usdz")
        
        // Act
        let identifiableURL = ImportModel.IdentifiableURL(url: url)
        
        // Assert
        XCTAssertEqual(identifiableURL.url.lastPathComponent, "import.usdz")
    }
    
    // MARK: - URL Deleting Path Extension Tests
    
    func testModelsModelIdentifiableCaptureURLDeletingPathExtension() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/model.usdz")
        
        // Act
        let identifiableURL = ModelsModel.IdentifiableCaptureURL(url: url)
        let urlWithoutExtension = identifiableURL.url.deletingPathExtension()
        
        // Assert
        XCTAssertEqual(urlWithoutExtension.lastPathComponent, "model")
    }
    
    func testImportModelIdentifiableURLDeletingPathExtension() {
        // Arrange
        let url = URL(fileURLWithPath: "/path/to/import.usdz")
        
        // Act
        let identifiableURL = ImportModel.IdentifiableURL(url: url)
        let urlWithoutExtension = identifiableURL.url.deletingPathExtension()
        
        // Assert
        XCTAssertEqual(urlWithoutExtension.lastPathComponent, "import")
    }
}
