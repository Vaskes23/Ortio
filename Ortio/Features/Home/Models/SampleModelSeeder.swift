//
//  SampleModelSeeder.swift
//  Ortio
//
//  Created by OpenAI on 07.04.2026.
//

import Foundation
import SwiftData

@MainActor
enum SampleModelSeeder {
    private static let bundledSampleNames = [
        "Untitled Object 2.usdz",
        "CitcularHome.usdz",
        "Atrium Pavilion.usdz",
        "Courtyard Townhouse.usdz",
        "Gallery Loft Interior.usdz",
        "Glass House Concept.usdz",
        "Modular Studio Facade.usdz",
        "Museum Stair Hall.usdz",
        "Riverside Office Tower.usdz",
        "Skyline Massing Study.usdz",
        "Timber Cabin Concept.usdz",
        "Urban Corner Block.usdz"
    ]

    private static let bundledSampleSubdirectories = [
        nil,
        "MockModels",
        "Resources/MockModels"
    ]

    static func seedIfNeeded(
        existingModels: [Models],
        context: ModelContext,
        fileManager: FileManager = .default,
        sampleURLs: [URL]? = nil
    ) {
        let sampleURLs = sampleURLs ?? bundledSampleURLs()

        guard !sampleURLs.isEmpty else { return }

        for (index, sourceURL) in sampleURLs.enumerated() {
            do {
                let destinationURL = try sampleDestinationURL(sourceURL: sourceURL, fileManager: fileManager)
                let sampleID = sourceURL.lastPathComponent
                let matchingModels = existingModels.filter {
                    $0.sampleSeedID == sampleID
                        || $0.model.standardizedFileURL == destinationURL.standardizedFileURL
                        || (
                            $0.imported
                                && $0.model.lastPathComponent == sampleID
                                && $0.model.deletingLastPathComponent().lastPathComponent.hasPrefix("Sample-")
                        )
                }

                if let preferredModel = preferredModel(from: matchingModels, defaultName: sampleID) {
                    migrateLegacyRenameIfNeeded(preferredModel, defaultName: sampleID)
                    if preferredModel.sampleSeedID != sampleID {
                        preferredModel.sampleSeedID = sampleID
                    }

                    for duplicate in matchingModels where duplicate !== preferredModel {
                        context.delete(duplicate)
                    }

                    // Always repair sample files and URLs against the current container path.
                    try copySampleIfNeeded(sourceURL: sourceURL, destinationURL: destinationURL, fileManager: fileManager)
                    if preferredModel.model.standardizedFileURL != destinationURL.standardizedFileURL {
                        preferredModel.model = destinationURL
                    }

                    continue
                }

                try copySampleIfNeeded(sourceURL: sourceURL, destinationURL: destinationURL, fileManager: fileManager)
                let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
                let fileSize = attributes[.size] as? Double ?? 0
                let model = Models(
                    name: sourceURL.lastPathComponent,
                    date: Date().addingTimeInterval(TimeInterval(index)),
                    favorite: false,
                    imported: true,
                    sampleSeedID: sampleID,
                    size: fileSize,
                    model: destinationURL
                )
                context.insert(model)
            } catch {
                continue
            }
        }

        try? context.save()
    }

    private static func bundledSampleURLs(bundle: Bundle = .main) -> [URL] {
        bundledSampleNames.compactMap { fileName in
            bundledSampleSubdirectories.lazy.compactMap { subdirectory in
                bundle.url(forResource: fileName, withExtension: nil, subdirectory: subdirectory)
            }.first
        }
    }

    private static func preferredModel(from models: [Models], defaultName: String) -> Models? {
        models.max { lhs, rhs in
            score(for: lhs, defaultName: defaultName) < score(for: rhs, defaultName: defaultName)
        }
    }

    private static func score(for model: Models, defaultName: String) -> Int {
        var score = 0
        if model.displayName != nil || model.name != defaultName {
            score += 4
        }
        if model.favorite {
            score += 2
        }
        if !(model.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            score += 1
        }
        return score
    }

    private static func migrateLegacyRenameIfNeeded(_ model: Models, defaultName: String) {
        guard model.normalizedDisplayName == nil,
              model.name != defaultName else {
            return
        }

        model.displayName = Models.normalizedDisplayTitle(from: model.name, fallbackURL: model.model)
        model.name = defaultName
    }

    static func sampleDestinationURL(sourceURL: URL, fileManager: FileManager) throws -> URL {
        let documentsDirectory = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let importsDirectory = documentsDirectory.appendingPathComponent(PathConstants.imports, isDirectory: true)
        let sampleDirectory = importsDirectory.appendingPathComponent(
            "Sample-\(sourceURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: " ", with: "-"))",
            isDirectory: true
        )

        if !fileManager.fileExists(atPath: importsDirectory.path, isDirectory: nil) {
            try fileManager.createDirectory(atPath: importsDirectory.path, withIntermediateDirectories: true, attributes: nil)
        }

        if !fileManager.fileExists(atPath: sampleDirectory.path, isDirectory: nil) {
            try fileManager.createDirectory(atPath: sampleDirectory.path, withIntermediateDirectories: true, attributes: nil)
        }

        return sampleDirectory.appendingPathComponent(sourceURL.lastPathComponent)
    }

    private static func copySampleIfNeeded(sourceURL: URL, destinationURL: URL, fileManager: FileManager) throws {
        if !fileManager.fileExists(atPath: destinationURL.path, isDirectory: nil) {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }
    }
}
