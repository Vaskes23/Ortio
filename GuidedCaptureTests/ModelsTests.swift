//
//  ModelsTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 23.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Testing
@testable import Ortio

@Suite
struct ModelsTests {

    var mockFileManager: MockFileManager
    var viewModel: ModelsViewModel

    init() {
        mockFileManager = MockFileManager()
        viewModel = ModelsViewModel(fileManager: mockFileManager)
    }

    @Test
    func urlsInAllModelsFolders() throws {
        // Arrange
        let expectedURLs = [
            URL(string: "file:///path/to/Documents/Scans/Session1/Models/model1.usdz")!,
            URL(string: "file:///path/to/Documents/Scans/Session1/Models/model2.usdz")!
        ]
        
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            return URL(string: "file:///path/to/Documents")!
        }
        
        mockFileManager.contentsOfDirectoryStub = { url, keys, mask in
            if url.absoluteString == "file:///path/to/Documents/Scans/" {
                return [URL(string: "file:///path/to/Documents/Scans/Session1")!]
            } else if url.absoluteString == "file:///path/to/Documents/Scans/Session1/Models/" {
                return expectedURLs
            } else {
                return []
            }
        }
        
        mockFileManager.fileExistsStub = { path, isDirectory in
            return path == "/path/to/Documents/Scans/Session1/Models"
        }

        // Act
        let modelURLs = try viewModel.urlsInAllModelsFolders()
        
        // Assert
        #expect(modelURLs == expectedURLs)
    }

    @Test
    func loadModelsFromDirectories() async {
        // Arrange
        let expectedURLs = [
            URL(string: "file:///path/to/Documents/Scans/Session1/Models/model1.usdz")!,
            URL(string: "file:///path/to/Documents/Scans/Session1/Models/model2.usdz")!
        ]
        
        mockFileManager.urlStub = { directory, domain, url, shouldCreate in
            return URL(string: "file:///path/to/Documents")!
        }
        
        mockFileManager.contentsOfDirectoryStub = { url, keys, mask in
            if url.absoluteString == "file:///path/to/Documents/Scans/" {
                return [URL(string: "file:///path/to/Documents/Scans/Session1")!]
            } else if url.absoluteString == "file:///path/to/Documents/Scans/Session1/Models/" {
                return expectedURLs
            } else {
                return []
            }
        }
        
        mockFileManager.fileExistsStub = { path, isDirectory in
            return path == "/path/to/Documents/Scans/Session1/Models"
        }

        // Act & Assert
        await confirmation("Load models from directories") { confirm in
            viewModel.loadModelsFromDirectories()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                #expect(self.viewModel.models.map { $0.url } == expectedURLs)
                confirm()
            }
        }
    }
}
