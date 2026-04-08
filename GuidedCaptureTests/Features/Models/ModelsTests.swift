//
//  ModelsTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 23.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
@testable import Ortio

@MainActor
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
            URL(fileURLWithPath: "/path/to/Documents/Scans/Session1/Models/model1.usdz"),
            URL(fileURLWithPath: "/path/to/Documents/Scans/Session1/Models/model2.usdz")
        ]

        mockFileManager.urlStub = { _, _, _, _ in
            URL(fileURLWithPath: "/path/to/Documents")
        }

        mockFileManager.contentsOfDirectoryStub = { url, _, _ in
            if url.path == "/path/to/Documents/Scans" {
                return [URL(fileURLWithPath: "/path/to/Documents/Scans/Session1")]
            } else if url.path == "/path/to/Documents/Scans/Session1/Models" {
                return expectedURLs
            } else {
                return []
            }
        }

        mockFileManager.fileExistsStub = { path, _ in
            path == "/path/to/Documents/Scans/Session1/Models"
        }

        // Act
        let modelURLs = try viewModel.urlsInAllModelsFolders()

        // Assert
        XCTAssertEqual(modelURLs, expectedURLs)
    }

    func testLoadModelsFromDirectories() throws {
        // Arrange
        let expectedURLs = [
            URL(fileURLWithPath: "/path/to/Documents/Scans/Session1/Models/model1.usdz"),
            URL(fileURLWithPath: "/path/to/Documents/Scans/Session1/Models/model2.usdz")
        ]

        mockFileManager.urlStub = { _, _, _, _ in
            URL(fileURLWithPath: "/path/to/Documents")
        }

        mockFileManager.contentsOfDirectoryStub = { url, _, _ in
            if url.path == "/path/to/Documents/Scans" {
                return [URL(fileURLWithPath: "/path/to/Documents/Scans/Session1")]
            } else if url.path == "/path/to/Documents/Scans/Session1/Models" {
                return expectedURLs
            } else {
                return []
            }
        }

        mockFileManager.fileExistsStub = { path, _ in
            path == "/path/to/Documents/Scans/Session1/Models"
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
