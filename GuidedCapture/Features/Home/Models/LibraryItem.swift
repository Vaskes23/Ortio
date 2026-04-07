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
    let notes: String

    init(
        title: String,
        subtitle: String,
        url: URL,
        source: Source,
        createdAt: Date,
        isFavorite: Bool,
        notes: String = ""
    ) {
        self.id = "\(source.rawValue):\(url.path)"
        self.title = title
        self.subtitle = subtitle
        self.url = url
        self.source = source
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.notes = notes
    }

    init(capturedURL: URL) {
        let metadata = LibraryItemMetadataStore.capturedMetadata(for: capturedURL)
        let title = metadata.displayName ?? capturedURL.deletingPathExtension().lastPathComponent
        let favoriteKey = "favorite_\(capturedURL.lastPathComponent)"
        let resourceValues = try? capturedURL.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        self.init(
            title: title,
            subtitle: "Photogrammetry capture",
            url: capturedURL,
            source: .captured,
            createdAt: resourceValues?.contentModificationDate ?? resourceValues?.creationDate ?? .distantPast,
            isFavorite: UserDefaults.standard.bool(forKey: favoriteKey),
            notes: metadata.notes
        )
    }

    init(importedModel: Models) {
        self.init(
            title: importedModel.name,
            subtitle: "Imported model",
            url: importedModel.model,
            source: .imported,
            createdAt: importedModel.date,
            isFavorite: importedModel.favorite,
            notes: importedModel.notes ?? ""
        )
    }

    var displayTitle: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return url.deletingPathExtension().lastPathComponent
        }

        if trimmedTitle.lowercased().hasSuffix(".usdz") {
            return (trimmedTitle as NSString).deletingPathExtension
        }

        return trimmedTitle
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

enum LibraryItemMetadataStore {
    private static let defaults = UserDefaults.standard
    private static let displayNameSuffix = "displayName"
    private static let notesSuffix = "notes"

    struct CapturedMetadata {
        let displayName: String?
        let notes: String
    }

    static func capturedMetadata(for url: URL) -> CapturedMetadata {
        CapturedMetadata(
            displayName: trimmedValue(forKey: key(for: url, suffix: displayNameSuffix)),
            notes: trimmedValue(forKey: key(for: url, suffix: notesSuffix)) ?? ""
        )
    }

    static func setCapturedDisplayName(_ displayName: String, for url: URL) {
        let baseName = url.deletingPathExtension().lastPathComponent
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = key(for: url, suffix: displayNameSuffix)

        guard !trimmedName.isEmpty, trimmedName != baseName else {
            defaults.removeObject(forKey: key)
            return
        }

        defaults.set(trimmedName, forKey: key)
    }

    static func setCapturedNotes(_ notes: String, for url: URL) {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = key(for: url, suffix: notesSuffix)

        guard !trimmedNotes.isEmpty else {
            defaults.removeObject(forKey: key)
            return
        }

        defaults.set(trimmedNotes, forKey: key)
    }

    static func clearCapturedMetadata(for url: URL) {
        defaults.removeObject(forKey: key(for: url, suffix: displayNameSuffix))
        defaults.removeObject(forKey: key(for: url, suffix: notesSuffix))
    }

    private static func key(for url: URL, suffix: String) -> String {
        "capturedMetadata:\(url.standardizedFileURL.path):\(suffix)"
    }

    private static func trimmedValue(forKey key: String) -> String? {
        guard let rawValue = defaults.string(forKey: key) else {
            return nil
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
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
