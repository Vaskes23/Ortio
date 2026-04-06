//
//  ModelsViewModelTests.swift
//  OrtioTests
//
//  Created by Matyas Vascak on 23.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
@testable import Ortio

final class ModelsViewModelTests: XCTestCase {
    var mockFileManager: MockFileManager!
    var viewModel: ModelsViewModel!
    
    override func setUpWithError() throws {
        mockFileManager = MockFileManager()
        viewModel = ModelsViewModel(fileManager: mockFileManager)
    }

    override func tearDownWithError() throws {
        mockFileManager = nil
        viewModel = nil
    }

    // MARK: - urlsInAllModelsFolders Tests
    
    func testUrlsInAllModelsFoldersWithNoSessions() throws {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")
        let scansFolderURL = documentsURL.appendingPathComponent("Scans")
        
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            return documentsURL
        }
        
        mockFileManager.contentsOfDirectoryStub = { url, keys, mask in
            if url == scansFolderURL {
                return [] // No sessions
            } else {
                return []
            }
        }
        
        mockFileManager.fileExistsStub = { path, isDirectory in
            return false
        }

        // Act
        let modelURLs = try viewModel.urlsInAllModelsFolders()
        
        // Assert
        XCTAssertEqual(modelURLs.count, 0)
    }
    
    func testUrlsInAllModelsFoldersWithSessionsButNoModelsFolder() throws {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")
        let scansFolderURL = documentsURL.appendingPathComponent("Scans")
        let session1URL = scansFolderURL.appendingPathComponent("Session1")
        let models1URL = session1URL.appendingPathComponent("Models")
        
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            return documentsURL
        }
        
        mockFileManager.contentsOfDirectoryStub = { url, keys, mask in
            if url == scansFolderURL {
                return [session1URL]
            } else {
                return []
            }
        }
        
        mockFileManager.fileExistsStub = { path, isDirectory in
            return false // Models folder doesn't exist
        }

        // Act
        let modelURLs = try viewModel.urlsInAllModelsFolders()
        
        // Assert
        XCTAssertEqual(modelURLs.count, 0)
    }
    
    func testUrlsInAllModelsFoldersWithEmptyModelsFolder() throws {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")
        let scansFolderURL = documentsURL.appendingPathComponent("Scans")
        let session1URL = scansFolderURL.appendingPathComponent("Session1")
        let models1URL = session1URL.appendingPathComponent("Models")
        
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            return documentsURL
        }
        
        mockFileManager.contentsOfDirectoryStub = { url, keys, mask in
            if url == scansFolderURL {
                return [session1URL]
            } else if url == models1URL {
                return [] // Empty models folder
            } else {
                return []
            }
        }
        
        mockFileManager.fileExistsStub = { path, isDirectory in
            return path == models1URL.path
        }

        // Act
        let modelURLs = try viewModel.urlsInAllModelsFolders()
        
        // Assert
        XCTAssertEqual(modelURLs.count, 0)
    }
    
    func testUrlsInAllModelsFoldersWhenDocumentsDirectoryNotFound() throws {
        // Arrange
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }
        
        // Act & Assert
        XCTAssertThrowsError(try viewModel.urlsInAllModelsFolders()) { error in
            XCTAssertEqual((error as NSError).domain, "Test")
            XCTAssertEqual((error as NSError).code, 1)
        }
    }
    
    func testUrlsInAllModelsFoldersWhenScansDirectoryNotFound() throws {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")
        
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            return documentsURL
        }
        
        mockFileManager.contentsOfDirectoryStub = { url, keys, mask in
            throw NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Scans directory not found"])
        }
        
        // Act & Assert
        XCTAssertThrowsError(try viewModel.urlsInAllModelsFolders()) { error in
            XCTAssertEqual((error as NSError).domain, "Test")
            XCTAssertEqual((error as NSError).code, 2)
        }
    }
    
    // MARK: - loadModelsFromDirectories Tests
    
    @MainActor
    func testLoadModelsFromDirectoriesWithError() throws {
        // Arrange
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }
        
        let expectation = self.expectation(description: "Load models from directories with error")
        
        // Act
        viewModel.loadModelsFromDirectories()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Assert
            XCTAssertEqual(self.viewModel.models.count, 0)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    // MARK: - Initialization Tests
    
    func testInitWithDefaultFileManager() {
        // Act
        let viewModelWithDefault = ModelsViewModel()
        
        // Assert
        XCTAssertNotNil(viewModelWithDefault)
        XCTAssertEqual(viewModelWithDefault.models.count, 0)
        XCTAssertNil(viewModelWithDefault.selectedModelForPreview)
    }
    
    func testInitWithCustomFileManager() {
        // Arrange
        let customFileManager = MockFileManager()
        
        // Act
        let viewModelWithCustom = ModelsViewModel(fileManager: customFileManager)
        
        // Assert
        XCTAssertNotNil(viewModelWithCustom)
        XCTAssertEqual(viewModelWithCustom.models.count, 0)
        XCTAssertNil(viewModelWithCustom.selectedModelForPreview)
    }
} 
