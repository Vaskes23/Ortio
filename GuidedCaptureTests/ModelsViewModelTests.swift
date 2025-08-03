//
//  ModelsViewModelTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 23.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Testing
@testable import Ortio

@Suite
struct ModelsViewModelTests {
    var mockFileManager: MockFileManager
    var viewModel: ModelsViewModel

    init() {
        mockFileManager = MockFileManager()
        viewModel = ModelsViewModel(fileManager: mockFileManager)
    }

    // MARK: - urlsInAllModelsFolders Tests
    
    @Test
    func urlsInAllModelsFoldersWithNoSessions() throws {
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
        #expect(modelURLs.count == 0)
    }

    @Test
    func urlsInAllModelsFoldersWithSessionsButNoModelsFolder() throws {
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
        #expect(modelURLs.count == 0)
    }

    @Test
    func urlsInAllModelsFoldersWithEmptyModelsFolder() throws {
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
        #expect(modelURLs.count == 0)
    }

    @Test
    func urlsInAllModelsFoldersWhenDocumentsDirectoryNotFound() {
        // Arrange
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }
        
        // Act & Assert
        let error = #expect(throws: (any Error).self) {
            try viewModel.urlsInAllModelsFolders()
        }
        let nsError = error as NSError
        #expect(nsError.domain == "Test")
        #expect(nsError.code == 1)
    }

    @Test
    func urlsInAllModelsFoldersWhenScansDirectoryNotFound() {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")
        
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            return documentsURL
        }
        
        mockFileManager.contentsOfDirectoryStub = { url, keys, mask in
            throw NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Scans directory not found"])
        }
        
        // Act & Assert
        let error = #expect(throws: (any Error).self) {
            try viewModel.urlsInAllModelsFolders()
        }
        let nsError = error as NSError
        #expect(nsError.domain == "Test")
        #expect(nsError.code == 2)
    }
    
    // MARK: - loadModelsFromDirectories Tests
    
    @Test
    func loadModelsFromDirectoriesWithError() async {
        // Arrange
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }
        
        // Act & Assert
        await confirmation("Load models from directories with error") { confirm in
            viewModel.loadModelsFromDirectories()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                #expect(self.viewModel.models.count == 0)
                confirm()
            }
        }
    }
    
    // MARK: - Initialization Tests
    
    @Test
    func initWithDefaultFileManager() {
        // Act
        let viewModelWithDefault = ModelsViewModel()
        
        // Assert
        #expect(viewModelWithDefault != nil)
        #expect(viewModelWithDefault.models.count == 0)
        #expect(viewModelWithDefault.selectedModelForPreview == nil)
    }

    @Test
    func initWithCustomFileManager() {
        // Arrange
        let customFileManager = MockFileManager()
        
        // Act
        let viewModelWithCustom = ModelsViewModel(fileManager: customFileManager)
        
        // Assert
        #expect(viewModelWithCustom != nil)
        #expect(viewModelWithCustom.models.count == 0)
        #expect(viewModelWithCustom.selectedModelForPreview == nil)
    }
}
