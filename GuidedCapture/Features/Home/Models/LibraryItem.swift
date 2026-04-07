//
//  LibraryItem.swift
//  GuidedCapture
//
//  Created by OpenAI on 07.04.2026.
//

import Foundation

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
    let subtitle: String
    let url: URL
    let source: Source
    let createdAt: Date
    let isFavorite: Bool

    init(
        title: String,
        subtitle: String,
        url: URL,
        source: Source,
        createdAt: Date,
        isFavorite: Bool
    ) {
        self.id = "\(source.rawValue):\(url.path)"
        self.title = title
        self.subtitle = subtitle
        self.url = url
        self.source = source
        self.createdAt = createdAt
        self.isFavorite = isFavorite
    }

    init(capturedURL: URL) {
        let title = capturedURL.deletingPathExtension().lastPathComponent
        let favoriteKey = "favorite_\(capturedURL.lastPathComponent)"
        let resourceValues = try? capturedURL.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        self.init(
            title: title,
            subtitle: "Photogrammetry capture",
            url: capturedURL,
            source: .captured,
            createdAt: resourceValues?.contentModificationDate ?? resourceValues?.creationDate ?? .distantPast,
            isFavorite: UserDefaults.standard.bool(forKey: favoriteKey)
        )
    }

    init(importedModel: Models) {
        self.init(
            title: importedModel.name,
            subtitle: "Imported model",
            url: importedModel.model,
            source: .imported,
            createdAt: importedModel.date,
            isFavorite: importedModel.favorite
        )
    }

    func matches(query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return true }

        return title.localizedCaseInsensitiveContains(normalizedQuery)
            || subtitle.localizedCaseInsensitiveContains(normalizedQuery)
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
