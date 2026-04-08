//
//  ImportView.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 24.12.2023.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Displays imported 3D models and provides file import functionality.
/// Uses `@Query` for SwiftData-backed model list and delegates all
/// business logic (import, delete) to `ImportViewModel`.
struct ImportView: View {
    @State var viewModel: ImportViewModel
    @State private var presentImporter = false
    @State private var selectedModelForPreview: LibraryPreviewItem?
    @State private var searchQuery = ""
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Models.date, order: .reverse) var storedModels: [Models] = []

    var filteredModels: [Models] {
        guard !searchQuery.isEmpty else { return storedModels }
        return storedModels.filter { model in
            model.name.localizedCaseInsensitiveContains(searchQuery)
                || model.displayTitle.localizedCaseInsensitiveContains(searchQuery)
                || (model.normalizedNotes ?? "").localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                storageSection
                importedSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Import")
            .searchable(text: $searchQuery, prompt: "Search files")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Button {
                        presentImporter = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .sensoryFeedback(.impact, trigger: presentImporter)
                    .accessibilityLabel("Import new 3D model")
                }
            }
            .fileImporter(
                isPresented: $presentImporter,
                allowedContentTypes: [.usd, .usdz, .realityFile],
                allowsMultipleSelection: true,
                onCompletion: { result in
                    Task {
                        await viewModel.handleImport(result: result, existingModels: storedModels, context: modelContext)
                    }
                }
            )
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .fullScreenCover(item: $selectedModelForPreview, onDismiss: {
                selectedModelForPreview = nil
            }, content: { item in
                ModelView(modelFile: item.url, endCaptureCallback: {
                    selectedModelForPreview = nil
                })
            })
        }
    }

    // MARK: - Sections

    private var storageSection: some View {
        Section("Storage location") {
            NavigationLink {
                StoragePickerView()
            } label: {
                Label("On My iPhone", systemImage: "externaldrive")
            }
        }
        .headerProminence(.increased)
    }

    private var importedSection: some View {
        Section("Imported objects") {
            ForEach(filteredModels) { model in
                FileRow(model: model) {
                    presentPreview(for: model.model)
                }
            }
            .onDelete { offsets in
                Task {
                    await viewModel.deleteModel(at: offsets, from: storedModels, context: modelContext)
                }
            }
        }
    }

    private func presentPreview(for url: URL) {
        switch LibraryPreviewItem.previewableResult(for: url) {
        case .success(let item):
            selectedModelForPreview = item
        case .failure(let error):
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - FileRow

/// A single row in the imported files list showing name, date, and a preview button.
struct FileRow: View {
    let model: Models
    let onPreview: () -> Void

    var body: some View {
        HStack {
            Label(model.displayTitle, systemImage: "cube.transparent")
                .lineLimit(1)
            Spacer()
            Text(model.date.formatted(.dateTime.day().month().year()))
                .foregroundStyle(.secondary)
                .font(.caption)
            Button(action: onPreview) {
                Image(systemName: "eye")
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Preview \(model.displayTitle)")
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Preview", systemImage: "eye") {
                onPreview()
            }
        }
    }
}

// MARK: - StoragePickerView

struct StoragePickerView: View {
    var body: some View {
        List {
            Section("Choose storage location") {
                Label("On My iPhone", systemImage: "iphone")
                Label("iCloud Drive", systemImage: "icloud")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Storage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ImportView(viewModel: ImportViewModel())
}
