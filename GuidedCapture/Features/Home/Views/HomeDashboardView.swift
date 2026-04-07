//
//  HomeDashboardView.swift
//  GuidedCapture
//
//  Created by OpenAI on 07.04.2026.
//

import SwiftData
import SwiftUI

private enum HomeSearchPresentationState {
    case idle
    case expanding
    case active
    case collapsing
}

struct HomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Models.date, order: .reverse) private var storedModels: [Models]
    @Query private var capturedMetadata: [CapturedModelMetadata]
    @Query private var users: [User]

    @Namespace private var searchTransitionNamespace
    @State private var searchViewModel = GlobalSearchViewModel()
    @State private var selectedFilter: LibraryHomeFilter = .all
    @State private var previewItem: LibraryPreviewItem?
    @State private var activeEditor: ModelEditorDestination?
    @State private var expandedNotesItemIDs: Set<String> = []
    @State private var searchPresentationState: HomeSearchPresentationState = .idle
    @State private var showingSettings = false
    @State private var showingTools = false
    @State private var showingCapture = false
    @State private var showingImportLibrary = false
    @State private var showingHelp = false
    @FocusState private var isSearchFieldFocused: Bool

    private var user: User? { users.first }

    private var filteredItems: [LibraryItem] {
        Array(searchViewModel.items(for: selectedFilter).prefix(12))
    }

    private var storedModelRefreshKey: String {
        let importedKey = storedModels
            .map {
                [
                    $0.name, $0.displayName ?? "", "\($0.favorite)",
                    $0.notes ?? "", $0.sampleSeedID ?? "",
                    $0.model.path, "\($0.date.timeIntervalSinceReferenceDate)"
                ].joined(separator: "|")
            }
            .joined(separator: "\n")
        let capturedKey = capturedMetadata
            .sorted { $0.modelURL.path < $1.modelURL.path }
            .map { "\($0.modelURL.path)|\($0.favorite)|\($0.displayName ?? "")|\($0.notes ?? "")" }
            .joined(separator: "\n")
        return importedKey + "\n" + capturedKey
    }

    private var capturedMetadataByURL: [URL: CapturedModelMetadataSnapshot] {
        Dictionary(uniqueKeysWithValues: capturedMetadata.map { metadata in
            (
                metadata.modelURL.standardizedFileURL,
                CapturedModelMetadataSnapshot(
                    displayName: metadata.normalizedDisplayName,
                    notes: metadata.normalizedNotes ?? "",
                    isFavorite: metadata.favorite
                )
            )
        })
    }

    private var isSearchExpanded: Bool {
        switch searchPresentationState {
        case .expanding, .active:
            return true
        case .idle, .collapsing:
            return false
        }
    }

    private var showsSearchResults: Bool {
        switch searchPresentationState {
        case .expanding, .active:
            return true
        case .idle, .collapsing:
            return false
        }
    }

    private var dashboardAnimation: Animation {
        .spring(response: 0.42, dampingFraction: 0.88)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            OrtioDesignSystem.shellGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    DashboardHeader(
                        user: user,
                        searchText: $searchViewModel.searchText,
                        searchPresentationState: searchPresentationState,
                        namespace: searchTransitionNamespace,
                        isSearchFieldFocused: $isSearchFieldFocused,
                        onSearchTap: openSearch,
                        onCloseSearch: closeSearch,
                        onSettings: { showingSettings = true }
                    )
                    .padding(.bottom, isSearchExpanded ? 20 : 28)

                    QuickActionsRow(
                        selectedFilter: $selectedFilter,
                        onOpenTools: { showingTools = true }
                    )
                    .frame(height: isSearchExpanded ? 0 : 110, alignment: .top)
                    .opacity(isSearchExpanded ? 0 : 1)
                    .offset(x: isSearchExpanded ? 180 : 0)
                    .clipped()
                    .allowsHitTesting(!isSearchExpanded)
                    .animation(dashboardAnimation, value: isSearchExpanded)

                    ZStack(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 28) {
                            DashboardSection(
                                title: selectedFilter.title,
                                items: filteredItems,
                                onSelect: selectItem,
                                onTogglePin: togglePin,
                                expandedNotesItemIDs: $expandedNotesItemIDs,
                                onChangeName: presentRename,
                                onAddNotes: presentNotes,
                                onToggleNotes: toggleNotes
                            )

                            if filteredItems.isEmpty {
                                EmptyLibraryCard(
                                    onScan: { showingCapture = true },
                                    onImport: { showingImportLibrary = true }
                                )
                            }
                        }
                        .opacity(showsSearchResults ? 0 : 1)
                        .offset(y: showsSearchResults ? 28 : 0)
                        .allowsHitTesting(!showsSearchResults)
                        .animation(dashboardAnimation, value: showsSearchResults)

                        GlobalSearchContent(
                            viewModel: searchViewModel,
                            onSelect: selectItem
                        )
                        .opacity(showsSearchResults ? 1 : 0)
                        .offset(y: showsSearchResults ? 0 : 34)
                        .allowsHitTesting(showsSearchResults)
                        .animation(dashboardAnimation, value: showsSearchResults)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, isSearchExpanded ? 40 : 120)
            }

            ScanPillButton(action: { showingCapture = true })
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .opacity(isSearchExpanded ? 0 : 1)
                .offset(y: isSearchExpanded ? 32 : 0)
                .allowsHitTesting(!isSearchExpanded)
                .animation(dashboardAnimation, value: isSearchExpanded)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            ImportedModelMigration.normalizeDisplayNamesIfNeeded(models: storedModels, context: modelContext)
            SampleModelSeeder.seedIfNeeded(existingModels: storedModels, context: modelContext)
            refreshCapturedItems()
        }
        .task(id: storedModelRefreshKey) {
            searchViewModel.updateImportedModels(storedModels)
            refreshCapturedItems()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshCapturedItems()
            }
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(item: $previewItem) { item in
            ModelView(modelFile: item.url) {
                previewItem = nil
            }
        }
        .sheet(item: $activeEditor) { destination in
            switch destination {
            case .rename(let item):
                RenameModelSheet(
                    item: item,
                    onSave: { renameItem(item, to: $0) }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            case .notes(let item):
                ModelNotesSheet(
                    item: item,
                    onSave: { updateNotes(for: item, notes: $0) }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingCapture) {
            LoadGuidedCaptureView()
        }
        .sheet(isPresented: $showingImportLibrary) {
            ImportView(viewModel: ImportViewModel())
        }
        .sheet(isPresented: $showingHelp) {
            HelpPageView(showInfo: $showingHelp)
                .padding()
        }
        .sheet(isPresented: $showingTools) {
            HomeToolsSheet(
                onNewScan: {
                    showingTools = false
                    showingCapture = true
                },
                onImport: {
                    showingTools = false
                    showingImportLibrary = true
                },
                onHelp: {
                    showingTools = false
                    showingHelp = true
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Error", isPresented: Binding(
            get: { searchViewModel.errorMessage != nil },
            set: { if !$0 { searchViewModel.errorMessage = nil } }
        )) {
            Button("OK") { searchViewModel.errorMessage = nil }
        } message: {
            Text(searchViewModel.errorMessage ?? "")
        }
    }

    private func selectItem(_ item: LibraryItem) {
        previewItem = LibraryPreviewItem(url: item.url)
    }

    private func openSearch() {
        guard searchPresentationState == .idle else { return }

        withAnimation(dashboardAnimation) {
            searchPresentationState = .expanding
        }

        Task {
            try? await Task.sleep(for: .milliseconds(280))
            guard searchPresentationState == .expanding else { return }
            searchPresentationState = .active
            isSearchFieldFocused = true
        }
    }

    private func closeSearch() {
        guard searchPresentationState == .active else { return }

        isSearchFieldFocused = false
        withAnimation(dashboardAnimation) {
            searchPresentationState = .collapsing
        }

        Task {
            try? await Task.sleep(for: .milliseconds(280))
            guard searchPresentationState == .collapsing else { return }
            searchPresentationState = .idle
        }
    }

    private func refreshCapturedItems() {
        searchViewModel.refreshCapturedItems(metadataByURL: capturedMetadataByURL)
    }

    private func presentRename(for item: LibraryItem) {
        activeEditor = .rename(item)
    }

    private func presentNotes(for item: LibraryItem) {
        activeEditor = .notes(item)
    }

    private func toggleNotes(for item: LibraryItem) {
        if expandedNotesItemIDs.contains(item.id) {
            expandedNotesItemIDs.remove(item.id)
        } else {
            expandedNotesItemIDs.insert(item.id)
        }
    }

    private func togglePin(_ item: LibraryItem) {
        switch item.source {
        case .captured:
            do {
                try CapturedModelMetadataStore.update(
                    url: item.url,
                    in: capturedMetadata,
                    context: modelContext
                ) { metadata in
                    metadata.favorite.toggle()
                }
            } catch {
                searchViewModel.errorMessage = "Could not update favorite: \(error.localizedDescription)"
            }
            refreshCapturedItems()
        case .imported:
            guard let model = storedModels.first(where: { $0.model == item.url }) else { return }
            model.favorite.toggle()
            try? modelContext.save()
            searchViewModel.updateImportedModels(storedModels)
        }
    }

    private func renameItem(_ item: LibraryItem, to proposedName: String) -> Bool {
        let trimmedName = proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        switch item.source {
        case .captured:
            do {
                try CapturedModelMetadataStore.update(
                    url: item.url,
                    in: capturedMetadata,
                    context: modelContext
                ) { metadata in
                    metadata.displayName = trimmedName == item.defaultDisplayTitle ? nil : trimmedName
                }
                refreshCapturedItems()
                return true
            } catch {
                searchViewModel.errorMessage = "Could not rename model: \(error.localizedDescription)"
                return false
            }
        case .imported:
            guard let model = storedModels.first(where: { $0.model == item.url }) else { return false }
            let originalDisplayName = model.displayName
            model.displayName = trimmedName == model.defaultDisplayTitle ? nil : trimmedName

            do {
                try modelContext.save()
                searchViewModel.updateImportedModels(storedModels)
                return true
            } catch {
                model.displayName = originalDisplayName
                searchViewModel.errorMessage = "Could not rename model: \(error.localizedDescription)"
                return false
            }
        }
    }

    private func updateNotes(for item: LibraryItem, notes: String) -> Bool {
        switch item.source {
        case .captured:
            do {
                try CapturedModelMetadataStore.update(
                    url: item.url,
                    in: capturedMetadata,
                    context: modelContext
                ) { metadata in
                    metadata.notes = notes
                }
                expandedNotesItemIDs.insert(item.id)
                refreshCapturedItems()
                return true
            } catch {
                searchViewModel.errorMessage = "Could not update notes: \(error.localizedDescription)"
                return false
            }
        case .imported:
            guard let model = storedModels.first(where: { $0.model == item.url }) else { return false }
            let originalNotes = model.notes
            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            model.notes = trimmedNotes.isEmpty ? nil : trimmedNotes

            do {
                try modelContext.save()
                expandedNotesItemIDs.insert(item.id)
                searchViewModel.updateImportedModels(storedModels)
                return true
            } catch {
                model.notes = originalNotes
                searchViewModel.errorMessage = "Could not update notes: \(error.localizedDescription)"
                return false
            }
        }
    }
}
