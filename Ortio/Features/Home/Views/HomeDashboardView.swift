//
//  HomeDashboardView.swift
//  GuidedCapture
//
//  Created by OpenAI on 07.04.2026.
//

import SwiftData
import SwiftUI

struct HomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Models.date, order: .reverse) private var storedModels: [Models]
    @Query private var capturedMetadata: [CapturedModelMetadata]
    @Query private var users: [User]
    private let libraryRepository = LibraryRepository()

    @State private var searchViewModel = GlobalSearchViewModel()
    @State private var selectedFilter: LibraryHomeFilter = .all
    @State private var previewItem: LibraryPreviewItem?
    @State private var activeEditor: ModelEditorDestination?
    @State private var expandedNotesItemIDs: Set<String> = []
    @State private var searchTransition = HomeSearchTransitionCoordinator()
    @State private var showingSettings = false
    @State private var showingTools = false
    @State private var showingCapture = false
    @State private var showingImportLibrary = false
    @State private var showingHelp = false
    @State private var hasBootstrappedLibrary = false
    @State private var libraryRefreshToken = 0
    @State private var searchAnimationTask: Task<Void, Never>?
    @FocusState private var isSearchFieldFocused: Bool

    private var user: User? { users.first }

    private var filteredItems: [LibraryItem] {
        Array(searchViewModel.items(for: selectedFilter).prefix(12))
    }

    private var displayedItems: [LibraryItem] {
        searchTransition.usesSearchResults ? searchViewModel.filteredItems : filteredItems
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

    private var shellAnimation: Animation {
        .spring(response: 0.34, dampingFraction: 0.84)
    }

    private var contentAnimation: Animation {
        .easeOut(duration: 0.12)
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
                        transition: searchTransition,
                        isSearchFieldFocused: $isSearchFieldFocused,
                        onSearchTap: openSearch,
                        onCloseSearch: closeSearch,
                        onSettings: { showingSettings = true }
                    )
                    .padding(.bottom, searchTransition.usesSearchResults ? 18 : 28)
                    .animation(shellAnimation, value: searchTransition.phase)

                    QuickActionsRow(
                        selectedFilter: $selectedFilter,
                        onOpenTools: { showingTools = true }
                    )
                    .frame(height: searchTransition.showsQuickActions ? 110 : 0, alignment: .top)
                    .opacity(searchTransition.showsQuickActions ? 1 : 0)
                    .clipped()
                    .allowsHitTesting(searchTransition.showsQuickActions)
                    .animation(contentAnimation, value: searchTransition.showsQuickActions)

                    VStack(alignment: .leading, spacing: 28) {
                        DashboardSection(
                            title: searchTransition.showsBrowseSectionChrome ? selectedFilter.title : nil,
                            items: displayedItems,
                            showsSearchEmptyState: searchTransition.usesSearchResults,
                            onSelect: selectItem,
                            onTogglePin: togglePin,
                            expandedNotesItemIDs: $expandedNotesItemIDs,
                            onChangeName: presentRename,
                            onAddNotes: presentNotes,
                            onToggleNotes: toggleNotes
                        )

                        if !searchTransition.usesSearchResults && filteredItems.isEmpty {
                            EmptyLibraryCard(
                                onScan: { showingCapture = true },
                                onImport: { showingImportLibrary = true }
                            )
                        }
                    }
                    .padding(.top, searchTransition.listTopPadding)
                    .offset(y: searchTransition.contentLiftOffset)
                    .animation(shellAnimation, value: searchTransition.phase)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, searchTransition.usesSearchResults ? 40 : 120)
            }

            ScanPillButton(action: { showingCapture = true })
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .opacity(searchTransition.showsScanButton ? 1 : 0)
                .allowsHitTesting(searchTransition.showsScanButton)
                .animation(contentAnimation, value: searchTransition.showsScanButton)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await bootstrapLibraryIfNeeded()
        }
        .task(id: libraryRefreshToken) {
            searchViewModel.updateImportedModels(storedModels)
            await refreshCapturedItems()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                requestLibraryRefresh()
            }
        }
        .onChange(of: storedModels) { _, _ in requestLibraryRefresh() }
        .onChange(of: capturedMetadata) { _, _ in requestLibraryRefresh() }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView()
        }
        .fullScreenCover(item: $previewItem) { item in
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
            LoadOrtioView()
        }
        .sheet(isPresented: $showingImportLibrary) {
            ImportView(viewModel: ImportViewModel(repository: libraryRepository))
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

    private func requestLibraryRefresh() {
        libraryRefreshToken &+= 1
    }

    private func bootstrapLibraryIfNeeded() async {
        guard !hasBootstrappedLibrary else { return }
        hasBootstrappedLibrary = true
        libraryRepository.normalizeImportedModelDisplayNamesIfNeeded(models: storedModels, context: modelContext)
        libraryRepository.seedSampleModelsIfNeeded(existingModels: storedModels, context: modelContext)
        await libraryRepository.pruneMissingImportedModelsIfNeeded(models: storedModels, context: modelContext)
        requestLibraryRefresh()
    }

    private func selectItem(_ item: LibraryItem) {
        switch LibraryPreviewItem.previewableResult(for: item.url) {
        case .success(let previewItem):
            self.previewItem = previewItem
        case .failure(let error):
            searchViewModel.errorMessage = error.localizedDescription
        }
    }

    private func openSearch() {
        guard searchTransition.phase == .idle else { return }

        searchAnimationTask?.cancel()

        withAnimation(shellAnimation) {
            searchTransition.phase = .expandingShell
        }

        searchAnimationTask = Task {
            try? await Task.sleep(for: HomeSearchTransitionCoordinator.shellStageDuration)
            guard searchTransition.phase == .expandingShell else { return }
            await MainActor.run {
                withAnimation(contentAnimation) {
                    searchTransition.phase = .revealingControls
                }
            }

            try? await Task.sleep(for: HomeSearchTransitionCoordinator.controlsStageDuration)
            guard searchTransition.phase == .revealingControls else { return }
            await MainActor.run {
                withAnimation(contentAnimation) {
                    searchTransition.phase = .active
                }
                isSearchFieldFocused = true
            }
        }
    }

    private func closeSearch() {
        guard searchTransition.canBeginClosing else { return }

        searchAnimationTask?.cancel()
        isSearchFieldFocused = false
        withAnimation(contentAnimation) {
            searchTransition.phase = .hidingControls
        }

        searchAnimationTask = Task {
            try? await Task.sleep(for: HomeSearchTransitionCoordinator.hideControlsDuration)
            guard searchTransition.phase == .hidingControls else { return }
            await MainActor.run {
                withAnimation(shellAnimation) {
                    searchTransition.phase = .collapsingShell
                }
            }

            try? await Task.sleep(for: HomeSearchTransitionCoordinator.collapseStageDuration)
            guard searchTransition.phase == .collapsingShell else { return }
            await MainActor.run {
                withAnimation(contentAnimation) {
                    searchTransition.phase = .idle
                }
            }
        }
    }

    private func refreshCapturedItems() async {
        await searchViewModel.refreshCapturedItems(metadataByURL: capturedMetadataByURL)
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
        do {
            try libraryRepository.toggleFavorite(
                for: item,
                storedModels: storedModels,
                capturedMetadata: capturedMetadata,
                context: modelContext
            )
            requestLibraryRefresh()
        } catch {
            searchViewModel.errorMessage = "Could not update favorite: \(error.localizedDescription)"
        }
    }

    private func renameItem(_ item: LibraryItem, to proposedName: String) -> Bool {
        do {
            try libraryRepository.rename(
                item,
                to: proposedName,
                storedModels: storedModels,
                capturedMetadata: capturedMetadata,
                context: modelContext
            )
            requestLibraryRefresh()
            return true
        } catch {
            searchViewModel.errorMessage = "Could not rename model: \(error.localizedDescription)"
            return false
        }
    }

    private func updateNotes(for item: LibraryItem, notes: String) -> Bool {
        do {
            try libraryRepository.updateNotes(
                for: item,
                notes: notes,
                storedModels: storedModels,
                capturedMetadata: capturedMetadata,
                context: modelContext
            )
            expandedNotesItemIDs.insert(item.id)
            requestLibraryRefresh()
            return true
        } catch {
            searchViewModel.errorMessage = "Could not update notes: \(error.localizedDescription)"
            return false
        }
    }
}
