//
//  GlobalSearchViewModel.swift
//  GuidedCapture
//
//  Created by OpenAI on 07.04.2026.
//

import Foundation
import Observation

@Observable
final class GlobalSearchViewModel {
    var searchText: String = ""
    var items: [LibraryItem] = []
    var errorMessage: String?

    @ObservationIgnored
    private let capturedLoader: ModelsViewModel

    @ObservationIgnored
    private var capturedItems: [LibraryItem] = []

    @ObservationIgnored
    private var importedItems: [LibraryItem] = []

    init(fileManager: FileManagerProtocol = FileManager.default) {
        self.capturedLoader = ModelsViewModel(fileManager: fileManager)
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

    func refreshCapturedItems() {
        Task.detached(priority: .userInitiated) { [capturedLoader] in
            do {
                let urls = try capturedLoader.urlsInAllModelsFolders()
                    .filter { $0.pathExtension.lowercased() == "usdz" }
                await MainActor.run {
                    self.replaceCapturedURLs(urls)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load models: \(error.localizedDescription)"
                }
            }
        }
    }

    func updateImportedModels(_ models: [Models]) {
        let mapped = models.map(LibraryItem.init(importedModel:))
        importedItems = mapped.sorted { Self.sortItems(lhs: $0, rhs: $1) }
        rebuildItems()
    }

    func replaceCapturedURLs(_ urls: [URL]) {
        let mapped = urls.map(LibraryItem.init(capturedURL:))
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
        if lhs.createdAt == rhs.createdAt {
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
        return lhs.createdAt > rhs.createdAt
    }
}
