//
//  ModelsTests.swift
//  OrtioTests
//
//  Created by Matyas Vascak on 23.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
@testable import Ortio

final class ModelsTests: XCTestCase {

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

    func testUrlsInAllModelsFolders() throws {
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
        XCTAssertEqual(modelURLs, expectedURLs)
    }

    @MainActor
    func testLoadModelsFromDirectories() throws {
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
        
        let expectation = self.expectation(description: "Load models from directories")
        
        // Act
        viewModel.loadModelsFromDirectories()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Assert
            XCTAssertEqual(self.viewModel.models.map { $0.url }, expectedURLs)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
}
