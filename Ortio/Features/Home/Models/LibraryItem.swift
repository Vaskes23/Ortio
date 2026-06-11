//
//  LibraryItem.swift
//  Ortio
//
//  Created by OpenAI on 07.04.2026.
//

import Foundation

/// Immutable metadata used when converting captured model URLs into library items.
struct CapturedModelMetadataSnapshot: Sendable {
    let displayName: String?
    let notes: String
    let isFavorite: Bool
}

/// Validation failures that prevent a model URL from opening in preview.
enum LibraryPreviewValidationError: LocalizedError {
    case nonLocalFile
    case unsupportedFormat
    case missingFile

    var errorDescription: String? {
        switch self {
        case .nonLocalFile:
            "This model is not stored as a local file."
        case .unsupportedFormat:
            "This file format is not supported for preview."
        case .missingFile:
            "The model file could not be found."
        }
    }
}

/// Display model that normalizes captured and imported library entries for Home.
///
/// Captured items are built from filesystem URLs plus optional metadata.
/// Imported items are built from SwiftData `Models` records. Keeping both
/// sources behind this value lets search, filters, preview, rename, notes, and
/// favorite actions share the same UI surface.
struct LibraryItem: Identifiable, Equatable {
    enum Source: String, CaseIterable, Identifiable {
        case captured
        case imported

        var id: String { rawValue }

        var title: String {
            switch self {
            case .captured: "Captured"
            case .imported: "Imported"
            }
        }

        var symbolName: String {
            switch self {
            case .captured: "camera.viewfinder"
            case .imported: "tray.and.arrow.down"
            }
        }
    }

    let id: String
    let title: String
    let displayNameOverride: String?
    let subtitle: String
    let url: URL
    let source: Source
    let createdAt: Date
    let isFavorite: Bool
    let notes: String

    init(
        title: String,
        displayNameOverride: String? = nil,
        subtitle: String,
        url: URL,
        source: Source,
        createdAt: Date,
        isFavorite: Bool,
        notes: String = ""
    ) {
        self.id = "\(source.rawValue):\(url.path)"
        self.title = title
        self.displayNameOverride = displayNameOverride?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.subtitle = subtitle
        self.url = url
        self.source = source
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.notes = notes
    }

    init(capturedURL: URL, metadata: CapturedModelMetadataSnapshot? = nil) {
        let resourceValues = try? capturedURL.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        self.init(
            title: capturedURL.lastPathComponent,
            displayNameOverride: metadata?.displayName,
            subtitle: "Photogrammetry capture",
            url: capturedURL,
            source: .captured,
            createdAt: resourceValues?.contentModificationDate ?? resourceValues?.creationDate ?? .distantPast,
            isFavorite: metadata?.isFavorite ?? false,
            notes: metadata?.notes ?? ""
        )
    }

    init(importedModel: Models) {
        self.init(
            title: importedModel.name,
            displayNameOverride: importedModel.normalizedDisplayName,
            subtitle: "Imported model",
            url: importedModel.model,
            source: .imported,
            createdAt: importedModel.date,
            isFavorite: importedModel.favorite,
            notes: importedModel.normalizedNotes ?? ""
        )
    }

    var defaultDisplayTitle: String {
        Models.normalizedDisplayTitle(from: title, fallbackURL: url)
    }

    var displayTitle: String {
        if let trimmedDisplayName = displayNameOverride?.trimmingCharacters(in: .whitespacesAndNewlines),
           !trimmedDisplayName.isEmpty {
            return trimmedDisplayName
        }

        return defaultDisplayTitle
    }

    func matches(query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return true }

        return title.localizedCaseInsensitiveContains(normalizedQuery)
            || displayTitle.localizedCaseInsensitiveContains(normalizedQuery)
            || subtitle.localizedCaseInsensitiveContains(normalizedQuery)
            || notes.localizedCaseInsensitiveContains(normalizedQuery)
            || url.lastPathComponent.localizedCaseInsensitiveContains(normalizedQuery)
    }
}

/// Filters shown in the Home quick-action row.
enum LibraryHomeFilter: String, CaseIterable, Identifiable {
    case all
    case captured
    case imported
    case favorites

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Recents"
        case .captured: "Captured"
        case .imported: "Imported"
        case .favorites: "Favorites"
        }
    }

    var symbolName: String {
        switch self {
        case .all: "clock"
        case .captured: "camera"
        case .imported: "square.and.arrow.down"
        case .favorites: "star"
        }
    }
}

/// Validated local model URL that can be presented by `ModelView`.
struct LibraryPreviewItem: Identifiable, Equatable {
    let url: URL

    var id: String {
        url.standardizedFileURL.path
    }

    init(url: URL) {
        self.url = url.standardizedFileURL
    }

    static func previewableResult(
        for url: URL,
        fileManager: FileManager = .default
    ) -> Result<LibraryPreviewItem, LibraryPreviewValidationError> {
        let normalizedURL = url.standardizedFileURL
        let supportedExtensions = ["usd", "usdz", "reality"]

        guard normalizedURL.isFileURL else {
            return .failure(.nonLocalFile)
        }

        guard supportedExtensions.contains(normalizedURL.pathExtension.lowercased()) else {
            return .failure(.unsupportedFormat)
        }

        guard fileManager.fileExists(atPath: normalizedURL.path) else {
            return .failure(.missingFile)
        }

        return .success(LibraryPreviewItem(url: normalizedURL))
    }
}
