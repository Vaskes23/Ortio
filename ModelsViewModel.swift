//
//  ModelsViewModel.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 07.05.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import Combine

/// View model that loads and manages models stored on disk.
class ModelsViewModel: ObservableObject {
    /// URLs for models found in the scans folder.
    @Published var models: [ModelsModel.IdentifiableCaptureURL] = []
    /// URL of the model currently selected for preview.
    @Published var selectedModelForPreview: ModelsModel.IdentifiableCaptureURL?

    private let fileManager: FileManagerProtocol

    /// Creates a new instance using the given ``FileManagerProtocol``.
    init(fileManager: FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }

    /// Loads model URLs from disk and updates ``models`` on the main thread.
    func loadModelsFromDirectories() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let modelURLs = try self.urlsInAllModelsFolders()
                let filteredModelURLs = modelURLs.filter { $0.pathExtension == "usdz" }
                DispatchQueue.main.async {
                    self.models = filteredModelURLs.map { ModelsModel.IdentifiableCaptureURL(url: $0) }
                }
            } catch {
                print("Error loading models: \(error.localizedDescription)")
            }
        }
    }

    /// Returns URLs for all models stored in scan directories.
    func urlsInAllModelsFolders() throws -> [URL] {
        let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let scansFolder = documentsDirectory.appendingPathComponent("Scans", isDirectory: true)
        
        var allModelURLs: [URL] = []
        let sessionDirectories = try fileManager.contentsOfDirectory(at: scansFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        for sessionDir in sessionDirectories {
            let modelsFolder = sessionDir.appendingPathComponent("Models", isDirectory: true)
            let exists = fileManager.fileExists(atPath: modelsFolder.path, isDirectory: nil)
            if exists {
                let modelURLs = try fileManager.contentsOfDirectory(at: modelsFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                allModelURLs.append(contentsOf: modelURLs)
            }
        }
        return allModelURLs
    }
}
