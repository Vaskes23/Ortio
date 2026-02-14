//
//  ImportTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
@testable import Ortio

final class ImportTests: XCTestCase {
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

    func testCreateUniqueFolderName() {
        let date = Date(timeIntervalSince1970: 0)
        let folderName = ImportViewModel.createUniqueFolderName(from: date)
        XCTAssertEqual(folderName, "Model_19700101010000") // Adjusted expected string to account for time zone
    }

    func testCreateNewScanDirectoryFailure() throws {
        // Arrange
        mockFileManager.urlStub = { _, _, _, _ in
            return URL(fileURLWithPath: "/path/to/Scans")
        }
        mockFileManager.createDirectoryStub = { _, _, _ in
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }
        
        // Act
        let newScanDirectory = viewModel.createNewScanDirectory()
        
        // Assert
        XCTAssertNil(newScanDirectory)
    }
}
