//
//  ImportTests.swift
//  OrtioTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Testing
import Foundation
@testable import Ortio

@Suite("Import Tests")
struct ImportTests {
    @Test
    func createUniqueFolderName() {
        let date = Date(timeIntervalSince1970: 0)
        let folderName = ImportViewModel.createUniqueFolderName(from: date)
        #expect(folderName == "Model_19700101000000")
    }

    @Test
    func createNewScanDirectoryFailure() {
        let mockFileManager = MockFileManager()
        let viewModel = ImportViewModel(fileManager: mockFileManager)

        // Arrange
        mockFileManager.urlStub = { _, _, _, _ in
            URL(fileURLWithPath: "/path/to/Scans")
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
