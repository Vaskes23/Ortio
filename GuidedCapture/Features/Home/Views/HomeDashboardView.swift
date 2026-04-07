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
            .map { "\($0.name)|\($0.favorite)|\($0.model.path)|\($0.date.timeIntervalSinceReferenceDate)" }
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
                        onTogglePin: togglePin
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
}

private struct DashboardHeader: View {
    let user: User?
    let onSearch: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Text("Ortio")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 0) {
                Button(action: onSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 46, height: 46)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Search")

                Rectangle()
                    .fill(OrtioDesignSystem.subtleBorder)
                    .frame(width: 1, height: 24)

                Button(action: onSettings) {
                    Group {
                        if let profileImage = user?.profileUIImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Text(userInitials)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Circle().fill(OrtioDesignSystem.accent))
                        }
                    }
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
                    .padding(.horizontal, 12)
                    .frame(height: 46)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open settings")
            }
            .ortioHeaderGlassCapsule()
        }
    }

    private var userInitials: String {
        let parts = (user?.name ?? "Ortio").split(separator: " ")
        let initials = parts.prefix(2).compactMap(\.first).map(String.init).joined()
        return initials.isEmpty ? "OR" : initials.uppercased()
    }
}

private struct QuickActionsRow: View {
    @Binding var selectedFilter: LibraryHomeFilter
    let onOpenTools: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach([LibraryHomeFilter.captured, .imported, .favorites], id: \.id) { filter in
                    HomeQuickActionButton(
                        title: filter.title,
                        systemName: filter.symbolName,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }

                HomeQuickActionButton(
                    title: "Tools",
                    systemName: "square.grid.2x2",
                    isSelected: false,
                    action: onOpenTools
                )
            }
            .padding(.vertical, 4)
        }
    }
}

private struct DashboardSection: View {
    let title: String
    let items: [LibraryItem]
    let onSelect: (LibraryItem) -> Void
    let onTogglePin: (LibraryItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            VStack(spacing: 12) {
                ForEach(items) { item in
                    LibraryCard(
                        item: item,
                        onSelect: { onSelect(item) },
                        onTogglePin: { onTogglePin(item) }
                    )
                }
            }
        }
    }
}

private struct LibraryCard: View {
    let item: LibraryItem
    let onSelect: () -> Void
    let onTogglePin: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: onSelect) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(OrtioDesignSystem.accentSoft)
                            .frame(width: 52, height: 52)

                        Image(systemName: item.source.symbolName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 8) {
                            Text(item.source.title)
                            Text(item.createdAt.formatted(.dateTime.month().day()))
                        }
                        .font(.subheadline)
                        .foregroundStyle(OrtioDesignSystem.mutedText)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onTogglePin) {
                Image(systemName: item.isFavorite ? "pin.fill" : "pin")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(item.isFavorite ? Color.orange : .secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isFavorite ? "Unpin design" : "Pin design")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ortioCardStyle()
    }
}

private struct EmptyLibraryCard: View {
    let onScan: () -> Void
    let onImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nothing here yet")
                .font(.title3.weight(.semibold))

            HStack(spacing: 12) {
                Button("Start Scan", action: onScan)
                    .buttonStyle(.borderedProminent)
                    .tint(.black)

                Button("Import File", action: onImport)
                    .buttonStyle(.bordered)
                    .tint(.primary)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ortioCardStyle()
    }
}

private struct HomeQuickActionButton: View {
    let title: String
    let systemName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? OrtioDesignSystem.accentSoft : OrtioDesignSystem.elevatedSurface)
                        .frame(width: 74, height: 74)
                        .overlay(Circle().stroke(OrtioDesignSystem.subtleBorder, lineWidth: 1))

                    Image(systemName: systemName)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.primary)
                }

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ScanPillButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Scan", systemImage: "camera")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .background(Capsule(style: .continuous).fill(Color.black.opacity(0.88)))
                .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 14)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start new scan")
    }
}

private struct HomeToolsSheet: View {
    let onNewScan: () -> Void
    let onImport: () -> Void
    let onHelp: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick tools")
                        .font(.largeTitle.weight(.bold))

                    ToolActionCard(
                        title: "New Scan",
                        systemName: "camera.viewfinder",
                        action: onNewScan
                    )

                    ToolActionCard(
                        title: "Import File",
                        systemName: "square.and.arrow.down",
                        action: onImport
                    )

                    ToolActionCard(
                        title: "Preview Help",
                        systemName: "questionmark.circle",
                        action: onHelp
                    )
                }
                .padding(20)
            }
            .background(OrtioDesignSystem.shellGradient.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct ToolActionCard: View {
    let title: String
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(OrtioDesignSystem.accentSoft)
                        .frame(width: 58, height: 58)

                    Image(systemName: systemName)
                        .font(.title3)
                        .foregroundStyle(.primary)
                }

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .ortioCardStyle()
        }
        .buttonStyle(.plain)
    }
}
