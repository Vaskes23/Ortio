//
//  ImportViewModel.swift
//  Ortio
//
//  Created by Matyas Vascak on 07.05.2024.
//

import SwiftData
import Foundation
import Observation
import os

/// Handles file import operations and scan directory management.
/// Accepts `FileManagerProtocol` for dependency injection in tests.
@Observable
class ImportViewModel {
    @ObservationIgnored
    private let fileManager: FileManagerProtocol

    /// Set when an import or delete operation fails. Drives the error alert in ImportView.
    var errorMessage: String?

    @ObservationIgnored
    private static let logger = Logger(
        subsystem: OrtioApp.subsystem,
        category: "ImportViewModel"
    )

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter
    }()

    init(fileManager: FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }

    /// Returns a unique folder name based on the file's creation date (e.g. "Model_20240507120000").
    static func createUniqueFolderName(from date: Date?) -> String {
        let dateString = timestampFormatter.string(from: date ?? Date())
        return "Model_\(dateString)"
    }

    /// Creates a new timestamped scan directory under `Documents/Scans/`.
    /// Returns the directory URL, or nil if creation fails.
    internal func createNewScanDirectory() -> URL? {
        guard let capturesFolder = rootScansFolder() else {
            Self.logger.error("Can't get user document dir!")
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: Date())
        let newCaptureDir = capturesFolder.appendingPathComponent(timestamp, isDirectory: true)

        Self.logger.debug("Creating capture path: \(newCaptureDir)")
        let capturePath = newCaptureDir.path
        do {
            try fileManager.createDirectory(atPath: capturePath, withIntermediateDirectories: true, attributes: nil)
            var url = URL(fileURLWithPath: capturePath)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
        } catch {
            Self.logger.error("Failed to create capture path: \(capturePath) error: \(error)")
            return nil
        }

        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: capturePath, isDirectory: &isDir)
        guard exists && isDir.boolValue else {
            return nil
        }

        return newCaptureDir
    }

    private func rootScansFolder() -> URL? {
        guard let documentsFolder = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            return nil
        }
        return documentsFolder.appendingPathComponent(PathConstants.scans, isDirectory: true)
    }

    // MARK: - Import Operations

    /// Deletes models at the given offsets, removing both the file system directory and SwiftData record.
    func deleteModel(at offsets: IndexSet, from storedModels: [Models], context: ModelContext) {
        for index in offsets {
            let modelToDelete = storedModels[index]
            let fileURL = modelToDelete.model
            let parentDirectory = fileURL.deletingLastPathComponent()

            do {
                if FileManager.default.fileExists(atPath: parentDirectory.path) {
                    try FileManager.default.removeItem(at: parentDirectory)
                    Self.logger.debug("Parent directory deleted: \(parentDirectory.path)")
                }
            } catch {
                Self.logger.error("Error deleting parent directory: \(error)")
            }

            context.delete(modelToDelete)
        }
    }

    /// Processes the result of the file importer, importing each selected file.
    func handleImport(result: Result<[URL], Error>, existingModels: [Models], context: ModelContext) {
        switch result {
        case .success(let urls):
            for url in urls {
                importSingleFile(url, existingModels: existingModels, context: context)
            }
        case .failure(let error):
            Self.logger.error("Import error: \(error)")
            errorMessage = "Failed to import: \(error.localizedDescription)"
        }
    }

    /// Copies a single file into `Documents/Imports/<uniqueFolder>/` and inserts a SwiftData record.
    /// Skips files that have already been imported.
    private func importSingleFile(_ url: URL, existingModels: [Models], context: ModelContext) {
        guard url.startAccessingSecurityScopedResource() else {
            Self.logger.error("Failed to get access to file: \(url)")
            return
        }

        let alreadyImported = existingModels.contains { $0.model == url }
        if alreadyImported {
            Self.logger.info("Model already imported: \(url.lastPathComponent)")
            url.stopAccessingSecurityScopedResource()
            return
        }

        do {
            let fm = FileManager.default
            let documentsDirectory = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let rootDirectory = documentsDirectory.appendingPathComponent(PathConstants.imports, isDirectory: true)

            if !fm.fileExists(atPath: rootDirectory.path) {
                try fm.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
            }

            let creationDate = try url.resourceValues(forKeys: [.creationDateKey]).creationDate
            let uniqueFolderName = ImportViewModel.createUniqueFolderName(from: creationDate)
            let modelFolderURL = rootDirectory.appendingPathComponent(uniqueFolderName, isDirectory: true)
            try fm.createDirectory(at: modelFolderURL, withIntermediateDirectories: true)

            let destinationURL = modelFolderURL.appendingPathComponent(url.lastPathComponent)
            try fm.copyItem(at: url, to: destinationURL)

            let fileDate = creationDate ?? Date()
            let fileSize = try fm.attributesOfItem(atPath: destinationURL.path)[.size] as? Double ?? 0
            let newModel = Models(
                name: url.lastPathComponent,
                date: fileDate,
                favorite: false,
                imported: true,
                size: fileSize,
                model: destinationURL
            )

            context.insert(newModel)
        } catch {
            Self.logger.error("File handling error: \(error)")
            errorMessage = "Import failed: \(error.localizedDescription)"
        }

        url.stopAccessingSecurityScopedResource()
    }
}
