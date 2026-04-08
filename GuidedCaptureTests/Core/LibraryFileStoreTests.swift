//
//  LibraryFileStoreTests.swift
//  GuidedCaptureTests
//

import XCTest
@testable import Ortio

final class LibraryFileStoreTests: XCTestCase {
    private var fileManager: MockFileManager!
    private var fileStore: LibraryFileStore!

    override func setUpWithError() throws {
        fileManager = MockFileManager()
        fileStore = LibraryFileStore(fileManager: fileManager)
    }

    override func tearDownWithError() throws {
        fileManager = nil
        fileStore = nil
    }

    func testCreateNewScanDirectoryCreatesTimestampedRootFolder() async {
        let documentsURL = URL(fileURLWithPath: "/Documents", isDirectory: true)
        let fixedDate = Date(timeIntervalSince1970: 1_234)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDirectory = documentsURL
            .appendingPathComponent(PathConstants.scans, isDirectory: true)
            .appendingPathComponent(formatter.string(from: fixedDate), isDirectory: true)

        fileStore = LibraryFileStore(fileManager: fileManager, now: { fixedDate })
        fileManager.urlStub = { _, _, _, _ in documentsURL }
        fileManager.fileExistsStub = { path, isDirectory in
            if path == expectedDirectory.path {
                isDirectory?.pointee = true
                return true
            }
            return false
        }

        let result = await fileStore.createNewScanDirectory()

        XCTAssertEqual(result, expectedDirectory)
        XCTAssertEqual(fileManager.createDirectoryCallCount, 1)
    }
}
