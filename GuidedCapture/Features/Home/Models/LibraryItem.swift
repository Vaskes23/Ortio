//
//  LibraryItem.swift
//  GuidedCapture
//
//  Created by OpenAI on 07.04.2026.
//

import Foundation

struct CapturedModelMetadataSnapshot: Sendable {
    let displayName: String?
    let notes: String
    let isFavorite: Bool
}

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

struct LibraryPreviewItem: Identifiable {
    let id = UUID()
    let url: URL
}
