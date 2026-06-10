//
//  ImportTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
@testable import Ortio

@MainActor
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
        XCTAssertTrue(folderName.hasPrefix("Model_"))
        // Format: Model_YYYYMMddHHmmss_XXXXXXXX (14 timestamp + 1 underscore + 8 UUID = 23)
        let suffix = String(folderName.dropFirst("Model_".count))
        XCTAssertEqual(suffix.count, 23)
        XCTAssertEqual(suffix[suffix.index(suffix.startIndex, offsetBy: 14)], "_")
    }

    func testCreateNewScanDirectoryFailure() async throws {
        // Arrange
        mockFileManager.urlStub = { _, _, _, _ in
            URL(fileURLWithPath: "/path/to/Scans")
        }
        mockFileManager.createDirectoryStub = { _, _, _ in
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }
        
        // Act
        let newScanDirectory = await viewModel.createNewScanDirectory()
        
        // Assert
        XCTAssertNil(newScanDirectory)
    }
}
