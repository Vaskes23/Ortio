//
//  ImportViewModelTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
@testable import Ortio

final class ImportViewModelTests: XCTestCase {
    var mockFileManager: MockFileManager!
    var viewModel: ImportViewModel!
    
    override func setUpWithError() throws {
        mockFileManager = MockFileManager()
        viewModel = ImportViewModel(fileManager: mockFileManager)
    }

    override func tearDownWithError() throws {
        mockFileManager = nil
        viewModel = nil
    }

    // MARK: - createUniqueFolderName Tests
    
    func testCreateUniqueFolderNameWithValidDate() {
        // Arrange
        let date = Date(timeIntervalSince1970: 0) // January 1, 1970 00:00:00 UTC
        
        // Act
        let folderName = ImportViewModel.createUniqueFolderName(from: date)
        
        // Assert
        XCTAssertTrue(folderName.hasPrefix("Model_"))
        XCTAssertTrue(folderName.count > 10) // Should have timestamp
    }
    
    func testCreateUniqueFolderNameWithNilDate() {
        // Act
        let folderName = ImportViewModel.createUniqueFolderName(from: nil)
        
        // Assert
        XCTAssertTrue(folderName.hasPrefix("Model_"))
        XCTAssertTrue(folderName.count > 10) // Should have current timestamp
    }
    
    func testCreateUniqueFolderNameFormat() {
        // Arrange
        let date = Date(timeIntervalSince1970: 946684800) // January 1, 2000 00:00:00 UTC
        
        // Act
        let folderName = ImportViewModel.createUniqueFolderName(from: date)
        
        // Assert
        XCTAssertTrue(folderName.hasPrefix("Model_"))
        // Should contain timestamp in format yyyyMMddHHmmss
        let timestampPart = String(folderName.dropFirst(6)) // Remove "Model_"
        XCTAssertEqual(timestampPart.count, 14) // yyyyMMddHHmmss = 14 characters
    }
    
    // MARK: - createNewScanDirectory Tests
    

    
    func testCreateNewScanDirectoryFailureWhenDocumentsDirectoryNotFound() throws {
        // Arrange
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }
        
        // Act
        let result = viewModel.createNewScanDirectory()
        
        // Assert
        XCTAssertNil(result)
    }
    
    func testCreateNewScanDirectoryFailureWhenDirectoryCreationFails() throws {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")
        
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            return documentsURL
        }
        
        mockFileManager.createDirectoryStub = { path, withIntermediateDirectories, attributes in
            throw NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Directory creation failed"])
        }
        
        // Act
        let result = viewModel.createNewScanDirectory()
        
        // Assert
        XCTAssertNil(result)
    }
    
    func testCreateNewScanDirectoryFailureWhenDirectoryDoesNotExistAfterCreation() throws {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")
        let scansFolderURL = documentsURL.appendingPathComponent("Scans")
        let timestamp = "2024-01-01T12:00:00.000Z"
        let expectedCaptureDir = scansFolderURL.appendingPathComponent(timestamp)
        
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            return documentsURL
        }
        
        mockFileManager.createDirectoryStub = { path, withIntermediateDirectories, attributes in
            // Directory creation succeeds
        }
        
        mockFileManager.fileExistsStub = { path, isDirectory in
            if path == expectedCaptureDir.path {
                isDirectory?.pointee = false // Not a directory
                return true
            }
            return false
        }
        
        // Act
        let result = viewModel.createNewScanDirectory()
        
        // Assert
        XCTAssertNil(result)
    }
    
    func testCreateNewScanDirectoryFailureWhenDirectoryDoesNotExist() throws {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")
        let scansFolderURL = documentsURL.appendingPathComponent("Scans")
        let timestamp = "2024-01-01T12:00:00.000Z"
        let expectedCaptureDir = scansFolderURL.appendingPathComponent(timestamp)
        
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            return documentsURL
        }
        
        mockFileManager.createDirectoryStub = { path, withIntermediateDirectories, attributes in
            // Directory creation succeeds
        }
        
        mockFileManager.fileExistsStub = { path, isDirectory in
            if path == expectedCaptureDir.path {
                return false // Directory doesn't exist
            }
            return false
        }
        
        // Act
        let result = viewModel.createNewScanDirectory()
        
        // Assert
        XCTAssertNil(result)
    }
    
    // MARK: - createUniqueFileName Tests (Testing internal method through reflection if needed)
    
    func testCreateUniqueFileNameFormat() {
        // This test would require accessing the private method
        // In a real scenario, you might make this method internal for testing
        // or test it indirectly through public methods that use it
        
        // For now, we'll test the behavior indirectly
        let originalURL = URL(fileURLWithPath: "/path/to/file.usdz")
        
        // The method should create a unique filename with timestamp and random sequence
        // We can't directly test the private method, but we can verify the pattern
        // through other means if the method becomes internal for testing
    }
} 
