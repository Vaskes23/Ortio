//
//  LibraryRepositoryTests.swift
//  OrtioTests
//
//  Created by OpenAI on 08.04.2026.
//

import XCTest
import SwiftData
@testable import Ortio

@MainActor
final class LibraryRepositoryTests: XCTestCase {
    private var fileManager: MockFileManager!
    private var repository: LibraryRepository!
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        fileManager = MockFileManager()
        repository = LibraryRepository(fileManager: fileManager)
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Models.self, CapturedModelMetadata.self, User.self, configurations: configuration)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        fileManager = nil
        repository = nil
        context = nil
        container = nil
    }

    func testCapturedModelURLsLoadsModelsAcrossSessionFolders() async throws {
        let documentsURL = URL(fileURLWithPath: "/Documents", isDirectory: true)
        let scansURL = documentsURL.appendingPathComponent("Scans", isDirectory: true)
        let sessionURL = scansURL.appendingPathComponent("Session1", isDirectory: true)
        let modelsURL = sessionURL.appendingPathComponent("Models", isDirectory: true)
        let capturedURL = modelsURL.appendingPathComponent("Tower.usdz")

        fileManager.urlStub = { _, _, _, _ in documentsURL }
        fileManager.contentsOfDirectoryStub = { url, _, _ in
            switch url {
            case scansURL:
                return [sessionURL]
            case modelsURL:
                return [capturedURL]
            default:
                return []
            }
        }
        fileManager.fileExistsStub = { path, isDirectory in
            if path == modelsURL.path {
                isDirectory?.pointee = true
                return true
            }
            return false
        }

        let urls = try await repository.capturedModelURLs()

        XCTAssertEqual(urls, [capturedURL])
    }

    func testImportFileCopiesFileAndInsertsModel() async throws {
        let documentsURL = URL(fileURLWithPath: "/Documents", isDirectory: true)
        let sourceDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sourceURL = sourceDirectory.appendingPathComponent("Lobby.usdz")
        try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        try Data("sample".utf8).write(to: sourceURL)
        defer {
            try? FileManager.default.removeItem(at: sourceDirectory)
        }

        fileManager.urlStub = { _, _, _, _ in documentsURL }
        fileManager.fileExistsStub = { _, _ in false }
        fileManager.createDirectoryStub = { _, _, _ in }
        fileManager.copyItemStub = { _, _ in }
        fileManager.attributesOfItemStub = { _ in [.size: 128.0] }

        try await repository.importFile(sourceURL, existingModels: [], context: context)

        let models = try context.fetch(FetchDescriptor<Models>())
        XCTAssertEqual(models.count, 1)
        XCTAssertEqual(models.first?.name, "Lobby.usdz")
        XCTAssertEqual(fileManager.copyItemCallCount, 1)
        XCTAssertEqual(fileManager.lastCopyItemParameters?.srcURL, sourceURL)
    }

    func testDeleteImportedModelsRemovesDirectoryAndRecord() async throws {
        let model = Models(
            name: "Lobby.usdz",
            date: Date(),
            favorite: false,
            imported: true,
            size: 128,
            model: URL(fileURLWithPath: "/Documents/Imports/Model_1/Lobby.usdz")
        )
        context.insert(model)
        try context.save()

        fileManager.fileExistsStub = { path, _ in
            path == "/Documents/Imports/Model_1"
        }
        fileManager.removeItemStub = { _ in }

        try await repository.deleteImportedModels(at: IndexSet(integer: 0), from: [model], context: context)

        XCTAssertEqual(fileManager.removeItemCallCount, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Models>()).count, 0)
    }

    func testToggleFavoriteUpdatesCapturedMetadata() throws {
        let url = URL(fileURLWithPath: "/Scans/Session/Models/Kitchen.usdz")
        let item = LibraryItem(capturedURL: url)

        try repository.toggleFavorite(
            for: item,
            storedModels: [],
            capturedMetadata: [],
            context: context
        )

        let metadata = try context.fetch(FetchDescriptor<CapturedModelMetadata>())
        XCTAssertEqual(metadata.count, 1)
        XCTAssertTrue(metadata.first?.favorite == true)
    }

    func testUpdateNotesPersistsImportedModelNotes() throws {
        let model = Models(
            name: "Lobby.usdz",
            date: Date(),
            favorite: false,
            imported: true,
            size: 128,
            model: URL(fileURLWithPath: "/Documents/Imports/Model_1/Lobby.usdz")
        )
        context.insert(model)
        try context.save()
        let item = LibraryItem(importedModel: model)

        try repository.updateNotes(
            for: item,
            notes: "Retake ceiling",
            storedModels: [model],
            capturedMetadata: [],
            context: context
        )

        XCTAssertEqual(model.notes, "Retake ceiling")
    }

    func testPruneMissingImportedModelsRemovesStaleRecords() async throws {
        let existingURL = URL(fileURLWithPath: "/Documents/Imports/Sample-A/Existing.usdz")
        let missingURL = URL(fileURLWithPath: "/Documents/Imports/Sample-B/Missing.usdz")

        let existingModel = Models(
            name: "Existing.usdz",
            date: Date(),
            favorite: false,
            imported: true,
            size: 128,
            model: existingURL
        )
        let missingModel = Models(
            name: "Missing.usdz",
            date: Date(),
            favorite: false,
            imported: true,
            size: 128,
            model: missingURL
        )

        context.insert(existingModel)
        context.insert(missingModel)
        try context.save()

        fileManager.fileExistsStub = { path, _ in
            path == existingURL.path
        }

        await repository.pruneMissingImportedModelsIfNeeded(
            models: [existingModel, missingModel],
            context: context
        )

        let remainingModels = try context.fetch(FetchDescriptor<Models>())
        XCTAssertEqual(remainingModels.count, 1)
        XCTAssertEqual(remainingModels.first?.model, existingURL)
    }
}
