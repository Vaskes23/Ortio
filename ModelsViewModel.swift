//
//  ModelsViewModel.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 07.05.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import Combine

class ModelsViewModel: ObservableObject{
    
    @Published var models: [ModelsModel.IdentifiableCaptureURL] = []
    @Published var selectedModelForPreview: ModelsModel.IdentifiableCaptureURL?
    
    func loadModelsFromDirectories() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let modelURLs = try self.urlsInAllModelsFolders()
                let filteredModelURLs = modelURLs.filter { $0.pathExtension == "usdz" } // Filter for .usdz files if needed
                DispatchQueue.main.async {
                    self.models = filteredModelURLs.map { ModelsModel.IdentifiableCaptureURL(url: $0) }
                }
            } catch {
                print("Error loading models: \(error.localizedDescription)")
            }
        }
    }
    
    private func urlsInAllModelsFolders() throws -> [URL] {
        let fileManager = FileManager.default
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
