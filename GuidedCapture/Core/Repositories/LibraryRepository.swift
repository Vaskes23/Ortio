//
//  LibraryRepository.swift
//  GuidedCapture
//
//  Created by OpenAI on 08.04.2026.
//

import Foundation
import SwiftData

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
    func capturedModelURLs() throws -> [URL]
    func createNewScanDirectory() -> URL?
    func normalizeImportedModelDisplayNamesIfNeeded(models: [Models], context: ModelContext)
    func seedSampleModelsIfNeeded(existingModels: [Models], context: ModelContext)
    func pruneMissingImportedModelsIfNeeded(models: [Models], context: ModelContext)
    func importFile(_ url: URL, existingModels: [Models], context: ModelContext) throws
    func deleteImportedModels(at offsets: IndexSet, from storedModels: [Models], context: ModelContext) throws
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
    private let fileManager: FileManagerProtocol
    private let now: () -> Date

    nonisolated init(
        fileManager: FileManagerProtocol = FileManager.default,
        now: @escaping () -> Date = Date.init
    ) {
        self.fileManager = fileManager
        self.now = now
    }

    static func createUniqueFolderName(from date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = formatter.string(from: date ?? Date())
        return "Model_\(dateString)"
    }

    func capturedModelURLs() throws -> [URL] {
        let documentsDirectory = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        let scansFolder = documentsDirectory.appendingPathComponent(PathConstants.scans, isDirectory: true)

        var allModelURLs: [URL] = []
        let sessionDirectories = try fileManager.contentsOfDirectory(
            at: scansFolder,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )

        for sessionDirectory in sessionDirectories {
            let modelsFolder = sessionDirectory.appendingPathComponent(PathConstants.models, isDirectory: true)
            let exists = fileManager.fileExists(atPath: modelsFolder.path, isDirectory: nil)
            if exists {
                let modelURLs = try fileManager.contentsOfDirectory(
                    at: modelsFolder,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles
                )
                allModelURLs.append(contentsOf: modelURLs)
            }
        }

        return allModelURLs
    }

    func createNewScanDirectory() -> URL? {
        guard let capturesFolder = rootScansFolder() else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: now())
        let newCaptureDir = capturesFolder.appendingPathComponent(timestamp, isDirectory: true)

        do {
            try fileManager.createDirectory(
                atPath: newCaptureDir.path,
                withIntermediateDirectories: true,
                attributes: nil
            )
            var url = URL(fileURLWithPath: newCaptureDir.path)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try? url.setResourceValues(resourceValues)
        } catch {
            return nil
        }

        var isDirectory = ObjCBool(false)
        let exists = fileManager.fileExists(atPath: newCaptureDir.path, isDirectory: &isDirectory)
        guard exists && isDirectory.boolValue else {
            return nil
        }

        return newCaptureDir
    }

    func normalizeImportedModelDisplayNamesIfNeeded(models: [Models], context: ModelContext) {
        ImportedModelMigration.normalizeDisplayNamesIfNeeded(models: models, context: context)
    }

    func seedSampleModelsIfNeeded(existingModels: [Models], context: ModelContext) {
        SampleModelSeeder.seedIfNeeded(existingModels: existingModels, context: context)
    }

    func pruneMissingImportedModelsIfNeeded(models: [Models], context: ModelContext) {
        let missingModels = models.filter { model in
            model.imported && !fileManager.fileExists(atPath: model.model.standardizedFileURL.path, isDirectory: nil)
        }

        guard !missingModels.isEmpty else { return }

        for model in missingModels {
            context.delete(model)
        }

        try? context.save()
    }

    func importFile(_ url: URL, existingModels: [Models], context: ModelContext) throws {
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

        let documentsDirectory = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let rootDirectory = documentsDirectory.appendingPathComponent(PathConstants.imports, isDirectory: true)

        if !fileManager.fileExists(atPath: rootDirectory.path, isDirectory: nil) {
            try fileManager.createDirectory(
                atPath: rootDirectory.path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        let creationDate = try url.resourceValues(forKeys: [.creationDateKey]).creationDate
        let uniqueFolderName = Self.createUniqueFolderName(from: creationDate)
        let modelFolderURL = rootDirectory.appendingPathComponent(uniqueFolderName, isDirectory: true)
        try fileManager.createDirectory(
            atPath: modelFolderURL.path,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let destinationURL = modelFolderURL.appendingPathComponent(url.lastPathComponent)
        try fileManager.copyItem(at: url, to: destinationURL)

        let fileDate = creationDate ?? now()
        let fileSize = try fileManager.attributesOfItem(atPath: destinationURL.path)[.size] as? Double ?? 0
        let newModel = Models(
            name: url.lastPathComponent,
            date: fileDate,
            favorite: false,
            imported: true,
            size: fileSize,
            model: destinationURL
        )

        context.insert(newModel)
        try context.save()
    }

    func deleteImportedModels(at offsets: IndexSet, from storedModels: [Models], context: ModelContext) throws {
        for index in offsets {
            let modelToDelete = storedModels[index]
            let parentDirectory = modelToDelete.model.deletingLastPathComponent()

            if fileManager.fileExists(atPath: parentDirectory.path, isDirectory: nil) {
                try fileManager.removeItem(at: parentDirectory)
            }

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

    private func rootScansFolder() -> URL? {
        guard let documentsFolder = try? fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else {
            return nil
        }

        return documentsFolder.appendingPathComponent(PathConstants.scans, isDirectory: true)
    }
}
