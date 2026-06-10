//
//  LibraryRepository.swift
//  GuidedCapture
//
//  Created by OpenAI on 08.04.2026.
//

import Foundation
import SwiftData
import os

enum LibraryRepositoryError: LocalizedError {
    case modelNotFound
    case accessDenied(URL)
    case emptyName

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "The selected model could not be found."
        case .accessDenied(let url):
            return "The app could not access \(url.lastPathComponent)."
        case .emptyName:
            return "The model name cannot be empty."
        }
    }
}

@MainActor
protocol LibraryRepositoryProtocol {
    func capturedModelURLs() async throws -> [URL]
    func createNewScanDirectory() async -> URL?
    func normalizeImportedModelDisplayNamesIfNeeded(models: [Models], context: ModelContext)
    func seedSampleModelsIfNeeded(existingModels: [Models], context: ModelContext)
    func pruneMissingImportedModelsIfNeeded(models: [Models], context: ModelContext) async
    func importFile(_ url: URL, existingModels: [Models], context: ModelContext) async throws
    func deleteImportedModels(at offsets: IndexSet, from storedModels: [Models], context: ModelContext) async throws
    func deleteImportedModels(_ models: [Models], context: ModelContext) async throws
    func toggleFavorite(
        for item: LibraryItem,
        storedModels: [Models],
        capturedMetadata: [CapturedModelMetadata],
        context: ModelContext
    ) throws
    func rename(
        _ item: LibraryItem,
        to proposedName: String,
        storedModels: [Models],
        capturedMetadata: [CapturedModelMetadata],
        context: ModelContext
    ) throws
    func updateNotes(
        for item: LibraryItem,
        notes: String,
        storedModels: [Models],
        capturedMetadata: [CapturedModelMetadata],
        context: ModelContext
    ) throws
}

@MainActor
final class LibraryRepository: LibraryRepositoryProtocol {
    private static let logger = Logger(subsystem: "com.ortio", category: "LibraryRepository")
    nonisolated private let fileStore: any LibraryFileStoreProtocol

    nonisolated init(fileStore: any LibraryFileStoreProtocol = LibraryFileStore()) {
        self.fileStore = fileStore
    }

    nonisolated convenience init(
        fileManager: FileManagerProtocol = FileManager.default,
        now: @escaping () -> Date = Date.init
    ) {
        self.init(fileStore: LibraryFileStore(fileManager: fileManager, now: now))
    }

    nonisolated static func createUniqueFolderName(from date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = formatter.string(from: date ?? Date())
        let uniqueSuffix = UUID().uuidString.prefix(8)
        return "Model_\(dateString)_\(uniqueSuffix)"
    }

    func capturedModelURLs() async throws -> [URL] {
        try await fileStore.capturedModelURLs()
    }

    func createNewScanDirectory() async -> URL? {
        await fileStore.createNewScanDirectory()
    }

    func normalizeImportedModelDisplayNamesIfNeeded(models: [Models], context: ModelContext) {
        ImportedModelMigration.normalizeDisplayNamesIfNeeded(models: models, context: context)
    }

    func seedSampleModelsIfNeeded(existingModels: [Models], context: ModelContext) {
        SampleModelSeeder.seedIfNeeded(existingModels: existingModels, context: context)
    }

    func pruneMissingImportedModelsIfNeeded(models: [Models], context: ModelContext) async {
        let importedModelURLs = models.filter(\.imported).map { $0.model.standardizedFileURL }
        let missingURLs = await fileStore.missingImportedModelURLs(in: importedModelURLs)
        let missingModels = models.filter { model in
            missingURLs.contains(model.model.standardizedFileURL)
        }

        guard !missingModels.isEmpty else { return }

        for model in missingModels {
            context.delete(model)
        }

        do {
            try context.save()
        } catch {
            Self.logger.warning("Failed to save after pruning missing models: \(error.localizedDescription)")
        }
    }

    func importFile(_ url: URL, existingModels: [Models], context: ModelContext) async throws {
        let hasSecurityScope = url.startAccessingSecurityScopedResource()
        if !hasSecurityScope && !url.isFileURL {
            throw LibraryRepositoryError.accessDenied(url)
        }
        defer {
            if hasSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let alreadyImported = existingModels.contains { $0.model.standardizedFileURL == url.standardizedFileURL }
        if alreadyImported {
            return
        }

        let importedFile = try await fileStore.importFile(from: url)
        let newModel = Models(
            name: url.lastPathComponent,
            date: importedFile.fileDate,
            favorite: false,
            imported: true,
            size: importedFile.fileSize,
            model: importedFile.destinationURL
        )

        context.insert(newModel)
        try context.save()
    }

    func deleteImportedModels(at offsets: IndexSet, from storedModels: [Models], context: ModelContext) async throws {
        for index in offsets {
            let modelToDelete = storedModels[index]
            try await fileStore.deleteImportedModelDirectory(containing: modelToDelete.model)

            context.delete(modelToDelete)
        }

        try context.save()
    }

    func deleteImportedModels(_ models: [Models], context: ModelContext) async throws {
        for modelToDelete in models {
            try await fileStore.deleteImportedModelDirectory(containing: modelToDelete.model)
            context.delete(modelToDelete)
        }
        try context.save()
    }

    func toggleFavorite(
        for item: LibraryItem,
        storedModels: [Models],
        capturedMetadata: [CapturedModelMetadata],
        context: ModelContext
    ) throws {
        switch item.source {
        case .captured:
            try CapturedModelMetadataStore.update(
                url: item.url,
                in: capturedMetadata,
                context: context
            ) { metadata in
                metadata.favorite.toggle()
            }
        case .imported:
            guard let model = storedModels.first(where: { $0.model == item.url }) else {
                throw LibraryRepositoryError.modelNotFound
            }
            model.favorite.toggle()
            try context.save()
        }
    }

    func rename(
        _ item: LibraryItem,
        to proposedName: String,
        storedModels: [Models],
        capturedMetadata: [CapturedModelMetadata],
        context: ModelContext
    ) throws {
        let trimmedName = proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw LibraryRepositoryError.emptyName
        }

        switch item.source {
        case .captured:
            try CapturedModelMetadataStore.update(
                url: item.url,
                in: capturedMetadata,
                context: context
            ) { metadata in
                metadata.displayName = trimmedName == item.defaultDisplayTitle ? nil : trimmedName
            }
        case .imported:
            guard let model = storedModels.first(where: { $0.model == item.url }) else {
                throw LibraryRepositoryError.modelNotFound
            }

            let originalDisplayName = model.displayName
            model.displayName = trimmedName == model.defaultDisplayTitle ? nil : trimmedName

            do {
                try context.save()
            } catch {
                model.displayName = originalDisplayName
                throw error
            }
        }
    }

    func updateNotes(
        for item: LibraryItem,
        notes: String,
        storedModels: [Models],
        capturedMetadata: [CapturedModelMetadata],
        context: ModelContext
    ) throws {
        switch item.source {
        case .captured:
            try CapturedModelMetadataStore.update(
                url: item.url,
                in: capturedMetadata,
                context: context
            ) { metadata in
                metadata.notes = notes
            }
        case .imported:
            guard let model = storedModels.first(where: { $0.model == item.url }) else {
                throw LibraryRepositoryError.modelNotFound
            }

            let originalNotes = model.notes
            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            model.notes = trimmedNotes.isEmpty ? nil : trimmedNotes

            do {
                try context.save()
            } catch {
                model.notes = originalNotes
                throw error
            }
        }
    }

}
