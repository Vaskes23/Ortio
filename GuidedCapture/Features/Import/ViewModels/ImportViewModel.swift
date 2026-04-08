//
//  ImportViewModel.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 07.05.2024.
//

import SwiftData
import Foundation
import Observation
import os

/// Handles file import operations and scan directory management.
/// Accepts `FileManagerProtocol` for dependency injection in tests.
@MainActor
@Observable
class ImportViewModel {
    @ObservationIgnored
    private let repository: LibraryRepositoryProtocol

    /// Set when an import or delete operation fails. Drives the error alert in ImportView.
    var errorMessage: String?

    @ObservationIgnored
    private static let logger = Logger(
        subsystem: GuidedCaptureSampleApp.subsystem,
        category: "ImportViewModel"
    )

    init(repository: LibraryRepositoryProtocol = LibraryRepository()) {
        self.repository = repository
    }

    convenience init(fileManager: FileManagerProtocol) {
        self.init(repository: LibraryRepository(fileManager: fileManager))
    }

    /// Returns a unique folder name based on the file's creation date (e.g. "Model_20240507120000").
    static func createUniqueFolderName(from date: Date?) -> String {
        LibraryRepository.createUniqueFolderName(from: date)
    }

    /// Creates a new timestamped scan directory under `Documents/Scans/`.
    /// Returns the directory URL, or nil if creation fails.
    internal func createNewScanDirectory() -> URL? {
        repository.createNewScanDirectory()
    }

    // MARK: - Import Operations

    /// Deletes models at the given offsets, removing both the file system directory and SwiftData record.
    func deleteModel(at offsets: IndexSet, from storedModels: [Models], context: ModelContext) {
        do {
            try repository.deleteImportedModels(at: offsets, from: storedModels, context: context)
        } catch {
            Self.logger.error("Error deleting imported model: \(error.localizedDescription)")
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
    }

    /// Processes the result of the file importer, importing each selected file.
    func handleImport(result: Result<[URL], Error>, existingModels: [Models], context: ModelContext) {
        switch result {
        case .success(let urls):
            for url in urls {
                do {
                    try repository.importFile(url, existingModels: existingModels, context: context)
                } catch {
                    Self.logger.error("File handling error: \(error.localizedDescription)")
                    errorMessage = "Import failed: \(error.localizedDescription)"
                }
            }
        case .failure(let error):
            Self.logger.error("Import error: \(error)")
            errorMessage = "Failed to import: \(error.localizedDescription)"
        }
    }
}
