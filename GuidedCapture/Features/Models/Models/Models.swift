//
//  Models.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 24.12.2023.
//

import Foundation
import SwiftData

/// SwiftData model for an imported 3D file. Stored under `Documents/Imports/`.
@Model final class Models: Identifiable {
    var name: String
    var displayName: String?
    var date: Date
    var imported: Bool
    var favorite: Bool
    var notes: String?
    var sampleSeedID: String?
    var size: Double
    @Attribute(.unique) var model: URL

    init(
        name: String,
        date: Date,
        favorite: Bool,
        imported: Bool,
        displayName: String? = nil,
        notes: String = "",
        sampleSeedID: String? = nil,
        size: Double,
        model: URL
    ) {
        self.name = name
        self.displayName = Models.normalizedValue(displayName)
        self.date = date
        self.favorite = favorite
        self.imported = imported
        self.notes = notes.isEmpty ? nil : notes
        self.sampleSeedID = sampleSeedID
        self.size = size
        self.model = model
    }

    var normalizedDisplayName: String? {
        Models.normalizedValue(displayName)
    }

    var normalizedNotes: String? {
        Models.normalizedValue(notes)
    }

    var defaultDisplayTitle: String {
        Self.normalizedDisplayTitle(from: name, fallbackURL: model)
    }

    var displayTitle: String {
        if let normalizedDisplayName {
            return normalizedDisplayName
        }
        return defaultDisplayTitle
    }

    static func normalizedDisplayTitle(from rawTitle: String, fallbackURL: URL) -> String {
        let trimmedTitle = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return fallbackURL.deletingPathExtension().lastPathComponent
        }

        if trimmedTitle.lowercased().hasSuffix(".usdz") {
            return (trimmedTitle as NSString).deletingPathExtension
        }

        return trimmedTitle
    }

    private static func normalizedValue(_ value: String?) -> String? {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmedValue.isEmpty else {
            return nil
        }

        return trimmedValue
    }
}

@Model final class CapturedModelMetadata: Identifiable {
    @Attribute(.unique) var modelURL: URL
    var displayName: String?
    var notes: String?
    var favorite: Bool

    init(modelURL: URL, displayName: String? = nil, notes: String? = nil, favorite: Bool = false) {
        self.modelURL = modelURL.standardizedFileURL
        self.displayName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.favorite = favorite
    }

    var normalizedDisplayName: String? {
        let trimmedValue = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue?.isEmpty == true ? nil : trimmedValue
    }

    var normalizedNotes: String? {
        let trimmedValue = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue?.isEmpty == true ? nil : trimmedValue
    }

    var isEmpty: Bool {
        !favorite && normalizedDisplayName == nil && normalizedNotes == nil
    }
}

enum CapturedModelMetadataStore {
    static func metadata(for url: URL, in items: [CapturedModelMetadata]) -> CapturedModelMetadata? {
        let normalizedURL = url.standardizedFileURL
        return items.first { $0.modelURL.standardizedFileURL == normalizedURL }
    }

    static func metadataMap(from items: [CapturedModelMetadata]) -> [URL: CapturedModelMetadata] {
        Dictionary(uniqueKeysWithValues: items.map { ($0.modelURL.standardizedFileURL, $0) })
    }

    @MainActor
    @discardableResult
    static func update(
        url: URL,
        in items: [CapturedModelMetadata],
        context: ModelContext,
        mutate: (CapturedModelMetadata) -> Void
    ) throws -> CapturedModelMetadata? {
        let normalizedURL = url.standardizedFileURL
        let existingMetadata = metadata(for: normalizedURL, in: items)
        let metadata = existingMetadata ?? CapturedModelMetadata(modelURL: normalizedURL)
        let shouldInsert = existingMetadata == nil

        mutate(metadata)
        metadata.displayName = metadata.normalizedDisplayName
        metadata.notes = metadata.normalizedNotes

        if metadata.isEmpty {
            if !shouldInsert {
                context.delete(metadata)
            }
            try context.save()
            return nil
        }

        if shouldInsert {
            context.insert(metadata)
        }

        try context.save()
        return metadata
    }
}

enum ImportedModelMigration {
    @MainActor
    static func normalizeDisplayNamesIfNeeded(models: [Models], context: ModelContext) {
        var didChange = false

        for model in models where model.imported {
            let defaultName = model.model.lastPathComponent
            guard model.normalizedDisplayName == nil,
                  model.name != defaultName else {
                continue
            }

            model.displayName = Models.normalizedDisplayTitle(from: model.name, fallbackURL: model.model)
            model.name = defaultName
            didChange = true
        }

        if didChange {
            try? context.save()
        }
    }
}
