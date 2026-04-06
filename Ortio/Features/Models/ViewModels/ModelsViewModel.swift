//
//  ModelsViewModel.swift
//  Ortio
//
//  Created by Matyas Vascak on 07.05.2024.
//

import Foundation
import Observation
import os

/// Loads scanned 3D models from the file system and provides search/filtering.
/// Accepts `FileManagerProtocol` for dependency injection in tests.
@Observable
class ModelsViewModel {
    var models: [ModelsModel.IdentifiableCaptureURL] = []
    var selectedModelForPreview: ModelsModel.IdentifiableCaptureURL?
    var searchText: String = ""

    /// Set when model loading fails. Drives the error alert in ModelsView.
    var errorMessage: String?

    @ObservationIgnored
    private let fileManager: FileManagerProtocol

    @ObservationIgnored
    private static let logger = Logger(
        subsystem: OrtioApp.subsystem,
        category: "ModelsViewModel"
    )

    init(fileManager: FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }

    /// Returns models filtered by search text. Only includes `.usdz` files.
    var filteredModels: [ModelsModel.IdentifiableCaptureURL] {
        guard !searchText.isEmpty else { return models }
        return models.filter { model in
            model.url.lastPathComponent.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Scans `Documents/Scans/*/Models/` for `.usdz` files on a background thread,
    /// then updates `models` on the main actor.
    @MainActor
    func loadModelsFromDirectories() {
        Task.detached(priority: .userInitiated) { [self] in
            do {
                let modelURLs = try self.urlsInAllModelsFolders()
                let usdzURLs = modelURLs.filter { $0.pathExtension == "usdz" }
                let mapped = usdzURLs.map { ModelsModel.IdentifiableCaptureURL(url: $0) }
                await MainActor.run {
                    self.models = mapped
                }
            } catch {
                Self.logger.error("Error loading models: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = "Failed to load models: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Walks all session directories under `Documents/Scans/` and collects model file URLs.
    func urlsInAllModelsFolders() throws -> [URL] {
        let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let scansFolder = documentsDirectory.appendingPathComponent(PathConstants.scans, isDirectory: true)

        var allModelURLs: [URL] = []
        let sessionDirectories = try fileManager.contentsOfDirectory(at: scansFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

        for sessionDir in sessionDirectories {
            let modelsFolder = sessionDir.appendingPathComponent(PathConstants.models, isDirectory: true)
            let exists = fileManager.fileExists(atPath: modelsFolder.path, isDirectory: nil)
            if exists {
                let modelURLs = try fileManager.contentsOfDirectory(at: modelsFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                allModelURLs.append(contentsOf: modelURLs)
            }
        }
        return allModelURLs
    }
}
