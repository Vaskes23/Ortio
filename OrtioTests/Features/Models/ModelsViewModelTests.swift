//
//  ModelsViewModelTests.swift
//  OrtioTests
//
//  Created by Matyas Vascak on 23.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
@testable import Ortio

@MainActor
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
    
    func testUrlsInAllModelsFoldersWithNoSessions() async throws {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")
        let scansFolderURL = documentsURL.appendingPathComponent("Scans")
        
        mockFileManager.urlStub = { _, _, _, _ in
            documentsURL
        }

        mockFileManager.contentsOfDirectoryStub = { url, _, _ in
            if url == scansFolderURL {
                return [] // No sessions
            } else {
                return []
            }
        }

        mockFileManager.fileExistsStub = { _, _ in
            false
        }

        // Act
        let modelURLs = try await viewModel.urlsInAllModelsFolders()
        
        // Assert
        XCTAssertEqual(modelURLs.count, 0)
    }
    
    func testUrlsInAllModelsFoldersWithSessionsButNoModelsFolder() async throws {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")
        let scansFolderURL = documentsURL.appendingPathComponent("Scans")
        let session1URL = scansFolderURL.appendingPathComponent("Session1")
        let models1URL = session1URL.appendingPathComponent("Models")
        
        mockFileManager.urlStub = { _, _, _, _ in
            documentsURL
        }

        mockFileManager.contentsOfDirectoryStub = { url, _, _ in
            if url == scansFolderURL {
                return [session1URL]
            } else {
                return []
            }
        }

        mockFileManager.fileExistsStub = { _, _ in
            false // Models folder doesn't exist
        }

        // Act
        let modelURLs = try await viewModel.urlsInAllModelsFolders()
        
        // Assert
        XCTAssertEqual(modelURLs.count, 0)
    }
    
    func testUrlsInAllModelsFoldersWithEmptyModelsFolder() async throws {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")
        let scansFolderURL = documentsURL.appendingPathComponent("Scans")
        let session1URL = scansFolderURL.appendingPathComponent("Session1")
        let models1URL = session1URL.appendingPathComponent("Models")
        
        mockFileManager.urlStub = { _, _, _, _ in
            documentsURL
        }

        mockFileManager.contentsOfDirectoryStub = { url, _, _ in
            if url == scansFolderURL {
                return [session1URL]
            } else if url == models1URL {
                return [] // Empty models folder
            } else {
                return []
            }
        }

        mockFileManager.fileExistsStub = { path, _ in
            path == models1URL.path
        }

        // Act
        let modelURLs = try await viewModel.urlsInAllModelsFolders()
        
        // Assert
        XCTAssertEqual(modelURLs.count, 0)
    }
    
    func testUrlsInAllModelsFoldersWhenDocumentsDirectoryNotFound() async throws {
        // Arrange
        mockFileManager.urlStub = { _, _, _, _ in
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }

        // Act & Assert
        await XCTAssertThrowsErrorAsync(
            { try await self.viewModel.urlsInAllModelsFolders() },
            errorHandler: { error in
                XCTAssertEqual((error as NSError).domain, "Test")
                XCTAssertEqual((error as NSError).code, 1)
            }
        )
    }
    
    func testUrlsInAllModelsFoldersWhenScansDirectoryNotFound() async throws {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")
        
        mockFileManager.urlStub = { _, _, _, _ in
            documentsURL
        }

        mockFileManager.contentsOfDirectoryStub = { _, _, _ in
            throw NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Scans directory not found"])
        }
        
        // Act & Assert
        await XCTAssertThrowsErrorAsync(
            { try await self.viewModel.urlsInAllModelsFolders() },
            errorHandler: { error in
                XCTAssertEqual((error as NSError).domain, "Test")
                XCTAssertEqual((error as NSError).code, 2)
            }
        )
    }
    
    // MARK: - loadModelsFromDirectories Tests
    
    func testLoadModelsFromDirectoriesWithError() async throws {
        // Arrange
        mockFileManager.urlStub = { _, _, _, _ in
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }

        await viewModel.loadModelsFromDirectories()
        XCTAssertEqual(viewModel.models.count, 0)
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

    func testIdentifiableCaptureURLUsesStableStandardizedPathIdentity() {
        let url = URL(fileURLWithPath: "/tmp/Models/Example.usdz")
        let identifiableURL = ModelsModel.IdentifiableCaptureURL(url: url)
        XCTAssertEqual(identifiableURL.id, url.standardizedFileURL.path)
    }
}

private func XCTAssertThrowsErrorAsync<T>(
    _ expression: () async throws -> T,
    _ errorHandler: (Error) -> Void
) async {
    do {
        _ = try await expression()
        XCTFail("Expected expression to throw an error")
    } catch {
        errorHandler(error)
    }
}
