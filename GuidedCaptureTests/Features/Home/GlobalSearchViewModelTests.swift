//
//  GlobalSearchViewModelTests.swift
//  GuidedCaptureTests
//
//  Created by OpenAI on 07.04.2026.
//

import XCTest
@testable import Ortio

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

    override func tearDown() {
        LibraryItemMetadataStore.clearCapturedMetadata(for: URL(fileURLWithPath: "/Scans/Session/Models/Renamed.usdz"))
        super.tearDown()
    }

    func testRefreshCapturedItemsLoadsCapturedModelsFromExistingDirectoryContract() {
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

        let expectation = expectation(description: "captured items refresh")

        viewModel.refreshCapturedItems()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            XCTAssertEqual(self.viewModel.items.count, 1)
            XCTAssertEqual(self.viewModel.items.first?.source, .captured)
            XCTAssertEqual(self.viewModel.items.first?.title, "Tower")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
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
        XCTAssertEqual(viewModel.items.first?.title, "Imported Lobby.usdz")
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

    func testCapturedMetadataOverridesDisplayNameAndNotes() {
        let capturedURL = URL(fileURLWithPath: "/Scans/Session/Models/Renamed.usdz")
        LibraryItemMetadataStore.setCapturedDisplayName("Living Room", for: capturedURL)
        LibraryItemMetadataStore.setCapturedNotes("North wall needs cleanup", for: capturedURL)

        let item = LibraryItem(capturedURL: capturedURL)

        XCTAssertEqual(item.displayTitle, "Living Room")
        XCTAssertEqual(item.notes, "North wall needs cleanup")
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
}
