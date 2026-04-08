//
//  GlobalSearchViewModel.swift
//  GuidedCapture
//
//  Created by OpenAI on 07.04.2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class GlobalSearchViewModel {
    var searchText: String = ""
    var items: [LibraryItem] = []
    var errorMessage: String?

    @ObservationIgnored
    private var capturedItems: [LibraryItem] = []

    @ObservationIgnored
    private var importedItems: [LibraryItem] = []

    @ObservationIgnored
    private let repository: LibraryRepositoryProtocol

    init(repository: LibraryRepositoryProtocol = LibraryRepository()) {
        self.repository = repository
    }

    convenience init(fileManager: FileManagerProtocol) {
        self.init(repository: LibraryRepository(fileManager: fileManager))
    }

    var filteredItems: [LibraryItem] {
        items.filter { $0.matches(query: searchText) }
    }

    var capturedResults: [LibraryItem] {
        filteredItems.filter { $0.source == .captured }
    }

    var importedResults: [LibraryItem] {
        filteredItems.filter { $0.source == .imported }
    }

    func items(for filter: LibraryHomeFilter) -> [LibraryItem] {
        switch filter {
        case .all:
            items
        case .captured:
            items.filter { $0.source == .captured }
        case .imported:
            items.filter { $0.source == .imported }
        case .favorites:
            items.filter(\.isFavorite)
        }
    }

    func refreshCapturedItems(metadataByURL: [URL: CapturedModelMetadataSnapshot] = [:]) async {
        do {
            let urls = try await repository.capturedModelURLs()
                .filter { $0.pathExtension.lowercased() == "usdz" }
            replaceCapturedURLs(urls, metadataByURL: metadataByURL)
        } catch {
            errorMessage = "Failed to load models: \(error.localizedDescription)"
        }
    }

    func updateImportedModels(_ models: [Models]) {
        let mapped = models.map(LibraryItem.init(importedModel:))
        importedItems = mapped.sorted { Self.sortItems(lhs: $0, rhs: $1) }
        rebuildItems()
    }

    func replaceCapturedURLs(_ urls: [URL], metadataByURL: [URL: CapturedModelMetadataSnapshot] = [:]) {
        let mapped = urls.map { url in
            LibraryItem(capturedURL: url, metadata: metadataByURL[url.standardizedFileURL])
        }
        capturedItems = mapped.sorted { Self.sortItems(lhs: $0, rhs: $1) }
        rebuildItems()
    }

    func replaceCapturedItems(_ items: [LibraryItem]) {
        capturedItems = items.sorted { Self.sortItems(lhs: $0, rhs: $1) }
        rebuildItems()
    }

    private func rebuildItems() {
        items = (capturedItems + importedItems).sorted(by: Self.sortItems(lhs:rhs:))
    }

    private static func sortItems(lhs: LibraryItem, rhs: LibraryItem) -> Bool {
        if lhs.isFavorite != rhs.isFavorite {
            return lhs.isFavorite && !rhs.isFavorite
        }

        if lhs.createdAt == rhs.createdAt {
            return lhs.displayTitle.localizedCaseInsensitiveCompare(rhs.displayTitle) == .orderedAscending
        }
        return lhs.createdAt > rhs.createdAt
    }
}
