//
//  GlobalSearchViewModelTests.swift
//  GuidedCaptureTests
//
//  Created by OpenAI on 07.04.2026.
//

import XCTest
@testable import Ortio

@MainActor
final class GlobalSearchViewModelTests: XCTestCase {
    var mockFileManager: MockFileManager!
    var viewModel: GlobalSearchViewModel!

    override func setUpWithError() throws {
        mockFileManager = MockFileManager()
        viewModel = GlobalSearchViewModel(fileManager: mockFileManager)
    }

    override func tearDownWithError() throws {
        mockFileManager = nil
        viewModel = nil
    }

    func testRefreshCapturedItemsLoadsCapturedModelsFromExistingDirectoryContract() async {
        let documentsURL = URL(fileURLWithPath: "/Documents", isDirectory: true)
        let scansURL = documentsURL.appendingPathComponent("Scans", isDirectory: true)
        let sessionURL = scansURL.appendingPathComponent("Session1", isDirectory: true)
        let modelsURL = sessionURL.appendingPathComponent("Models", isDirectory: true)
        let capturedURL = modelsURL.appendingPathComponent("Tower.usdz")

        mockFileManager.urlStub = { _, _, _, _ in documentsURL }
        mockFileManager.contentsOfDirectoryStub = { url, _, _ in
            switch url {
            case scansURL:
                return [sessionURL]
            case modelsURL:
                return [capturedURL]
            default:
                return []
            }
        }
        mockFileManager.fileExistsStub = { path, isDirectory in
            if path == modelsURL.path {
                isDirectory?.pointee = true
                return true
            }
            return false
        }

        await viewModel.refreshCapturedItems()
        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items.first?.source, .captured)
        XCTAssertEqual(viewModel.items.first?.displayTitle, "Tower")
    }

    func testUpdateImportedModelsAddsImportedItems() {
        let imported = Models(
            name: "Imported Lobby.usdz",
            date: Date(timeIntervalSince1970: 2_000),
            favorite: false,
            imported: true,
            size: 512,
            model: URL(fileURLWithPath: "/Imports/Lobby.usdz")
        )

        viewModel.updateImportedModels([imported])

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items.first?.source, .imported)
        XCTAssertEqual(viewModel.items.first?.displayTitle, "Imported Lobby")
    }

    func testFilteredItemsMatchesAcrossCapturedAndImportedResults() {
        let capturedItem = LibraryItem(
            title: "Tower Capture",
            subtitle: "Photogrammetry capture",
            url: URL(fileURLWithPath: "/Scans/Tower.usdz"),
            source: .captured,
            createdAt: Date(),
            isFavorite: false
        )
        let imported = Models(
            name: "Tower Import.usdz",
            date: Date(),
            favorite: false,
            imported: true,
            size: 2048,
            model: URL(fileURLWithPath: "/Imports/Tower-Import.usdz")
        )

        viewModel.replaceCapturedItems([capturedItem])
        viewModel.updateImportedModels([imported])
        viewModel.searchText = "tower"

        XCTAssertEqual(viewModel.filteredItems.count, 2)
        XCTAssertEqual(viewModel.capturedResults.count, 1)
        XCTAssertEqual(viewModel.importedResults.count, 1)
    }

    func testFavoritesFilterReturnsOnlyFavoriteItems() {
        let favoriteImported = Models(
            name: "Favorite Model.usdz",
            date: Date(),
            favorite: true,
            imported: true,
            size: 1024,
            model: URL(fileURLWithPath: "/Imports/Favorite.usdz")
        )
        let regularImported = Models(
            name: "Regular Model.usdz",
            date: Date().addingTimeInterval(-100),
            favorite: false,
            imported: true,
            size: 1024,
            model: URL(fileURLWithPath: "/Imports/Regular.usdz")
        )

        viewModel.updateImportedModels([favoriteImported, regularImported])

        let favoriteItems = viewModel.items(for: .favorites)

        XCTAssertEqual(favoriteItems.count, 1)
        XCTAssertEqual(favoriteItems.first?.title, "Favorite Model.usdz")
    }

    func testFavoritesFilterUsesPinnedPresentation() {
        XCTAssertEqual(LibraryHomeFilter.favorites.title, "Pinned")
        XCTAssertEqual(LibraryHomeFilter.favorites.symbolName, "pin.fill")
        XCTAssertEqual(LibraryHomeFilter.favorites.symbolRotationDegrees, 40)
    }

    func testFavoriteItemsAreSortedToTopOfRecents() {
        let olderFavorite = Models(
            name: "Pinned.usdz",
            date: Date(timeIntervalSince1970: 1_000),
            favorite: true,
            imported: true,
            size: 1024,
            model: URL(fileURLWithPath: "/Imports/Pinned.usdz")
        )
        let newerRegular = Models(
            name: "Recent.usdz",
            date: Date(timeIntervalSince1970: 2_000),
            favorite: false,
            imported: true,
            size: 1024,
            model: URL(fileURLWithPath: "/Imports/Recent.usdz")
        )

        viewModel.updateImportedModels([newerRegular, olderFavorite])

        XCTAssertEqual(viewModel.items.first?.title, "Pinned.usdz")
        XCTAssertTrue(viewModel.items.first?.isFavorite == true)
    }

    func testImportedDisplayNameOverridesDefaultTitle() {
        let imported = Models(
            name: "Imported Lobby.usdz",
            date: Date(),
            favorite: false,
            imported: true,
            displayName: "Lobby Hero",
            size: 512,
            model: URL(fileURLWithPath: "/Imports/Lobby.usdz")
        )

        viewModel.updateImportedModels([imported])

        XCTAssertEqual(viewModel.items.first?.displayTitle, "Lobby Hero")
        XCTAssertEqual(viewModel.items.first?.title, "Imported Lobby.usdz")
    }

    func testCapturedMetadataOverridesDisplayNameAndNotes() {
        let capturedURL = URL(fileURLWithPath: "/Scans/Session/Models/Renamed.usdz")
        let metadata = CapturedModelMetadataSnapshot(
            displayName: "Living Room",
            notes: "North wall needs cleanup",
            isFavorite: true
        )

        let item = LibraryItem(capturedURL: capturedURL, metadata: metadata)

        XCTAssertEqual(item.displayTitle, "Living Room")
        XCTAssertEqual(item.notes, "North wall needs cleanup")
        XCTAssertTrue(item.isFavorite)
    }

    func testFilteredItemsMatchesAgainstNotes() {
        let capturedItem = LibraryItem(
            title: "Entry",
            subtitle: "Photogrammetry capture",
            url: URL(fileURLWithPath: "/Scans/Entry.usdz"),
            source: .captured,
            createdAt: Date(),
            isFavorite: false,
            notes: "Needs better lighting near the door"
        )

        viewModel.replaceCapturedItems([capturedItem])
        viewModel.searchText = "lighting"

        XCTAssertEqual(viewModel.filteredItems.count, 1)
        XCTAssertEqual(viewModel.filteredItems.first?.displayTitle, "Entry")
    }

    func testReplaceCapturedURLsUsesSwiftDataMetadata() {
        let capturedURL = URL(fileURLWithPath: "/Scans/Session/Models/Kitchen.usdz")
        let metadata = CapturedModelMetadataSnapshot(
            displayName: "Kitchen Pass",
            notes: "Retake ceiling",
            isFavorite: true
        )

        viewModel.replaceCapturedURLs([capturedURL], metadataByURL: [capturedURL: metadata])

        XCTAssertEqual(viewModel.items.first?.displayTitle, "Kitchen Pass")
        XCTAssertEqual(viewModel.items.first?.notes, "Retake ceiling")
        XCTAssertEqual(viewModel.items.first?.isFavorite, true)
    }

    func testLibraryPreviewItemUsesStandardizedURLPathAsIdentity() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = temporaryDirectory.appendingPathComponent("Preview.usdz")

        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data())
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let aliasedURL = temporaryDirectory
            .appendingPathComponent("folder", isDirectory: true)
            .deletingLastPathComponent()
            .appendingPathComponent("Preview.usdz")

        let firstResult = LibraryPreviewItem.previewableResult(for: fileURL)
        let secondResult = LibraryPreviewItem.previewableResult(for: aliasedURL)

        guard case .success(let firstItem) = firstResult else {
            return XCTFail("Expected first preview item to validate")
        }
        guard case .success(let secondItem) = secondResult else {
            return XCTFail("Expected second preview item to validate")
        }

        XCTAssertEqual(firstItem.id, secondItem.id)
        XCTAssertEqual(firstItem.url, secondItem.url)
    }
}
