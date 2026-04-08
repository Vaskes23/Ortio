//
//  ModelsViewModel.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 07.05.2024.
//

import Foundation
import Observation
import os

/// Loads scanned 3D models from the file system and provides search/filtering.
/// Accepts `FileManagerProtocol` for dependency injection in tests.
@MainActor
@Observable
class ModelsViewModel {
    var models: [ModelsModel.IdentifiableCaptureURL] = []
    var selectedModelForPreview: LibraryPreviewItem?
    var searchText: String = ""

    /// Set when model loading fails. Drives the error alert in ModelsView.
    var errorMessage: String?

    @ObservationIgnored
    private let repository: LibraryRepositoryProtocol

    @ObservationIgnored
    private static let logger = Logger(
        subsystem: GuidedCaptureSampleApp.subsystem,
        category: "ModelsViewModel"
    )

    init(repository: LibraryRepositoryProtocol = LibraryRepository()) {
        self.repository = repository
    }

    convenience init(fileManager: FileManagerProtocol) {
        self.init(repository: LibraryRepository(fileManager: fileManager))
    }

    /// Returns models filtered by search text. Only includes `.usdz` files.
    var filteredModels: [ModelsModel.IdentifiableCaptureURL] {
        guard !searchText.isEmpty else { return models }
        return models.filter { model in
            model.url.lastPathComponent.localizedCaseInsensitiveContains(searchText)
        }
    }

    func loadModelsFromDirectories() {
        do {
            let modelURLs = try repository.capturedModelURLs()
            let usdzURLs = modelURLs.filter { $0.pathExtension == "usdz" }
            models = usdzURLs.map { ModelsModel.IdentifiableCaptureURL(url: $0) }
        } catch {
            Self.logger.error("Error loading models: \(error.localizedDescription)")
            errorMessage = "Failed to load models: \(error.localizedDescription)"
        }
    }

    func urlsInAllModelsFolders() throws -> [URL] {
        try repository.capturedModelURLs()
    }
}
