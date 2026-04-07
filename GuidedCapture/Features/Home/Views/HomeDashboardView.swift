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
    @Query private var users: [User]

    @State private var searchViewModel = GlobalSearchViewModel()
    @State private var selectedFilter: LibraryHomeFilter = .all
    @State private var previewItem: LibraryPreviewItem?
    @State private var activeEditor: ModelEditorDestination?
    @State private var showingSearch = false
    @State private var showingSettings = false
    @State private var showingTools = false
    @State private var showingCapture = false
    @State private var showingImportLibrary = false
    @State private var showingHelp = false

    private var user: User? { users.first }

    private var filteredItems: [LibraryItem] {
        Array(searchViewModel.items(for: selectedFilter).prefix(12))
    }

    private var storedModelRefreshKey: String {
        storedModels
            .map { "\($0.name)|\($0.favorite)|\($0.notes ?? "")|\($0.model.path)|\($0.date.timeIntervalSinceReferenceDate)" }
            .joined(separator: "\n")
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            OrtioDesignSystem.shellGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    DashboardHeader(
                        user: user,
                        onSearch: { showingSearch = true },
                        onSettings: { showingSettings = true }
                    )

                    QuickActionsRow(
                        selectedFilter: $selectedFilter,
                        onOpenTools: { showingTools = true }
                    )

                    DashboardSection(
                        title: selectedFilter.title,
                        items: filteredItems,
                        onSelect: selectItem,
                        onTogglePin: togglePin,
                        onChangeName: presentRename,
                        onAddNotes: presentNotes
                    )

                    if filteredItems.isEmpty {
                        EmptyLibraryCard(
                            onScan: { showingCapture = true },
                            onImport: { showingImportLibrary = true }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }

            ScanPillButton(action: { showingCapture = true })
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            SampleModelSeeder.seedIfNeeded(existingModels: storedModels, context: modelContext)
            searchViewModel.refreshCapturedItems()
        }
        .task(id: storedModelRefreshKey) {
            searchViewModel.updateImportedModels(storedModels)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                searchViewModel.refreshCapturedItems()
            }
        }
        .fullScreenCover(isPresented: $showingSearch) {
            GlobalSearchView(viewModel: searchViewModel) {
                showingSearch = false
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

    private func presentRename(for item: LibraryItem) {
        activeEditor = .rename(item)
    }

    private func presentNotes(for item: LibraryItem) {
        activeEditor = .notes(item)
    }

    private func togglePin(_ item: LibraryItem) {
        switch item.source {
        case .captured:
            UserDefaults.standard.set(!item.isFavorite, forKey: "favorite_\(item.url.lastPathComponent)")
            searchViewModel.refreshCapturedItems()
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
            LibraryItemMetadataStore.setCapturedDisplayName(trimmedName, for: item.url)
            searchViewModel.refreshCapturedItems()
            return true
        case .imported:
            guard let model = storedModels.first(where: { $0.model == item.url }) else { return false }
            let originalName = model.name
            model.name = trimmedName

            do {
                try modelContext.save()
                searchViewModel.updateImportedModels(storedModels)
                return true
            } catch {
                model.name = originalName
                searchViewModel.errorMessage = "Could not rename model: \(error.localizedDescription)"
                return false
            }
        }
    }

    private func updateNotes(for item: LibraryItem, notes: String) -> Bool {
        switch item.source {
        case .captured:
            LibraryItemMetadataStore.setCapturedNotes(notes, for: item.url)
            searchViewModel.refreshCapturedItems()
            return true
        case .imported:
            guard let model = storedModels.first(where: { $0.model == item.url }) else { return false }
            let originalNotes = model.notes
            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            model.notes = trimmedNotes.isEmpty ? nil : trimmedNotes

            do {
                try modelContext.save()
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
