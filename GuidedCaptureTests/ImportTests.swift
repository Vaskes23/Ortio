//
//  ImportTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Testing
@testable import Ortio

@Suite
struct ImportTests {
    var mockFileManager: MockFileManager
    var viewModel: ImportViewModel

    init() {
        mockFileManager = MockFileManager()
        viewModel = ImportViewModel(fileManager: mockFileManager)
    }

    deinit {
        // cleanup
    }

    @Test
    func createUniqueFolderName() {
        let date = Date(timeIntervalSince1970: 0)
        let folderName = ImportViewModel.createUniqueFolderName(from: date)
        #expect(folderName == "Model_19700101010000") // Adjusted expected string to account for time zone
    }

    @Test
    func createNewScanDirectoryFailure() {
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
        #expect(newScanDirectory == nil)
    }
}
