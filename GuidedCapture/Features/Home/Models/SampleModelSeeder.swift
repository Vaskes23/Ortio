//
//  SampleModelSeeder.swift
//  GuidedCapture
//
//  Created by OpenAI on 07.04.2026.
//

import Foundation
import SwiftData

@MainActor
enum SampleModelSeeder {
    private static let bundledSampleNames = [
        "Untitled Object 2.usdz",
        "CitcularHome.usdz"
    ]

    static func seedIfNeeded(
        existingModels: [Models],
        context: ModelContext,
        fileManager: FileManager = .default
    ) {
        let existingNames = Set(existingModels.map(\.name))
        let sampleURLs = bundledSampleNames.compactMap { fileName in
            Bundle.main.url(forResource: fileName, withExtension: nil)
                ?? Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "MockModels")
        }

        guard !sampleURLs.isEmpty else { return }

        for (index, sourceURL) in sampleURLs.enumerated() where !existingNames.contains(sourceURL.lastPathComponent) {
            do {
                let destinationURL = try copySampleIfNeeded(sourceURL: sourceURL, fileManager: fileManager)
                let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
                let fileSize = attributes[.size] as? Double ?? 0
                let model = Models(
                    name: sourceURL.lastPathComponent,
                    date: Date().addingTimeInterval(TimeInterval(index)),
                    favorite: false,
                    imported: true,
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

    private static func copySampleIfNeeded(sourceURL: URL, fileManager: FileManager) throws -> URL {
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

        if !fileManager.fileExists(atPath: importsDirectory.path) {
            try fileManager.createDirectory(at: importsDirectory, withIntermediateDirectories: true)
        }

        if !fileManager.fileExists(atPath: sampleDirectory.path) {
            try fileManager.createDirectory(at: sampleDirectory, withIntermediateDirectories: true)
        }

        let destinationURL = sampleDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        if !fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }

        return destinationURL
    }
}
