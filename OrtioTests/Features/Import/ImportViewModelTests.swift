//
//  ImportViewModelTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
@testable import Ortio

@MainActor
final class ImportViewModelTests: XCTestCase {
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

    // MARK: - createUniqueFolderName Tests

    func testCreateUniqueFolderNameWithValidDate() {
        // Arrange
        let date = Date(timeIntervalSince1970: 0) // January 1, 1970 00:00:00 UTC

        // Act
        let folderName = ImportViewModel.createUniqueFolderName(from: date)

        // Assert
        XCTAssertTrue(folderName.hasPrefix("Model_"))
        XCTAssertTrue(folderName.count > 10) // Should have timestamp
    }

    func testCreateUniqueFolderNameWithNilDate() {
        // Act
        let folderName = ImportViewModel.createUniqueFolderName(from: nil)

        // Assert
        XCTAssertTrue(folderName.hasPrefix("Model_"))
        XCTAssertTrue(folderName.count > 10) // Should have current timestamp
    }

    func testCreateUniqueFolderNameFormat() {
        // Arrange
        let date = Date(timeIntervalSince1970: 946684800) // January 1, 2000 00:00:00 UTC

        // Act
        let folderName = ImportViewModel.createUniqueFolderName(from: date)

        // Assert
        XCTAssertTrue(folderName.hasPrefix("Model_"))
        // Should contain timestamp + UUID suffix
        let afterPrefix = String(folderName.dropFirst(6)) // Remove "Model_"
        XCTAssertTrue(afterPrefix.count > 14, "Folder name should include UUID suffix beyond timestamp")
    }

    func testCreateUniqueFolderNameProducesDistinctNamesForSameDate() {
        // Arrange — two imports with the exact same creation date
        let date = Date(timeIntervalSince1970: 946684800)

        // Act
        let name1 = ImportViewModel.createUniqueFolderName(from: date)
        let name2 = ImportViewModel.createUniqueFolderName(from: date)

        // Assert — must differ to prevent folder collision
        XCTAssertNotEqual(name1, name2, "Two calls with the same date must produce distinct folder names")
    }

    // MARK: - createNewScanDirectory Tests

    func testCreateNewScanDirectoryFailureWhenDocumentsDirectoryNotFound() async throws {
        // Arrange
        mockFileManager.urlStub = { _, _, _, _ in
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }

        // Act
        let result = await viewModel.createNewScanDirectory()

        // Assert
        XCTAssertNil(result)
    }

    func testCreateNewScanDirectoryFailureWhenDirectoryCreationFails() async throws {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")

        mockFileManager.urlStub = { _, _, _, _ in
            documentsURL
        }

        mockFileManager.createDirectoryStub = { _, _, _ in
            throw NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Directory creation failed"])
        }

        // Act
        let result = await viewModel.createNewScanDirectory()

        // Assert
        XCTAssertNil(result)
    }

    func testCreateNewScanDirectoryFailureWhenDirectoryDoesNotExistAfterCreation() async throws {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")

        mockFileManager.urlStub = { _, _, _, _ in
            documentsURL
        }

        mockFileManager.fileExistsStub = { path, isDirectory in
            if path.contains("/Documents/Scans/") {
                isDirectory?.pointee = false
                return true
            }
            return false
        }

        // Act
        let result = await viewModel.createNewScanDirectory()

        // Assert
        XCTAssertNil(result)
    }

    func testCreateNewScanDirectoryFailureWhenDirectoryDoesNotExist() async throws {
        // Arrange
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")

        mockFileManager.urlStub = { _, _, _, _ in
            documentsURL
        }

        mockFileManager.fileExistsStub = { _, _ in false }

        // Act
        let result = await viewModel.createNewScanDirectory()

        // Assert
        XCTAssertNil(result)
    }

    func testCreateNewScanDirectorySuccess() async {
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")

        mockFileManager.urlStub = { _, _, _, _ in documentsURL }
        mockFileManager.fileExistsStub = { path, isDirectory in
            if path.contains("/Documents/Scans/") {
                isDirectory?.pointee = true
                return true
            }
            return false
        }

        let result = await viewModel.createNewScanDirectory()

        XCTAssertNotNil(result)
        XCTAssertEqual(mockFileManager.createDirectoryCallCount, 1)
    }
}
