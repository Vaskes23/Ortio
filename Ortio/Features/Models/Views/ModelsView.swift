//
//  ModelsView.swift
//  ModelCapture
//
//  Created by Matyas Vascak on 23.12.2023.
//

import SwiftUI
import SwiftData
import QuickLookThumbnailing
import os

/// Grid view of scanned 3D models with search, favorites, and thumbnail previews.
/// Delegates model loading and filtering to `ModelsViewModel`.
struct ModelsView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewModel: ModelsViewModel
    @Query private var capturedMetadata: [CapturedModelMetadata]
    @Query var users: [User]
    private let libraryRepository = LibraryRepository()

    @State private var scaleEffect: CGFloat = 1.0
    @State private var navigateToSettings = false
    @State private var showingNewScan = false
    @State private var showingHelp = false

    var user: User? {
        users.first
    }

    private var metadataByURL: [URL: CapturedModelMetadata] {
        CapturedModelMetadataStore.metadataMap(from: capturedMetadata)
    }

    private var filteredModels: [ModelsModel.IdentifiableCaptureURL] {
        let normalizedQuery = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return viewModel.models }

        return viewModel.models.filter { model in
            let metadata = metadataByURL[model.url.standardizedFileURL]
            let displayName = metadata?.normalizedDisplayName ?? model.url.deletingPathExtension().lastPathComponent
            let notes = metadata?.normalizedNotes ?? ""
            return displayName.localizedCaseInsensitiveContains(normalizedQuery)
                || notes.localizedCaseInsensitiveContains(normalizedQuery)
                || model.url.lastPathComponent.localizedCaseInsensitiveContains(normalizedQuery)
        }
    }

    let columns = [GridItem(.adaptive(minimum: 120), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(filteredModels) { model in
                        ModelCard(
                            model: model,
                            metadata: metadataByURL[model.url.standardizedFileURL],
                            onToggleFavorite: {
                                toggleFavorite(for: model)
                            },
                            action: {
                                presentPreview(for: model.url)
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Models")
            .searchable(text: $viewModel.searchText, prompt: "Search models or notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileAvatar(user: user, scaleEffect: scaleEffect) {
                        withAnimation(.spring()) {
                            scaleEffect = 1.5
                        }
                        Task {
                            try? await Task.sleep(for: .milliseconds(200))
                            withAnimation(.spring()) {
                                scaleEffect = 1.0
                                navigateToSettings = true
                            }
                        }
                    }
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        showingNewScan = true
                    } label: {
                        Label("New Scan", systemImage: "camera.viewfinder")
                    }
                    .sensoryFeedback(.selection, trigger: showingNewScan)

                    Spacer()

                    Button {
                        showingHelp = true
                    } label: {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                    .sensoryFeedback(.selection, trigger: showingHelp)
                }
            }
            .task {
                await viewModel.loadModelsFromDirectories()
            }
            .fullScreenCover(item: $viewModel.selectedModelForPreview, onDismiss: {
                viewModel.selectedModelForPreview = nil
            }, content: { item in
                ModelView(modelFile: item.url, endCaptureCallback: {
                    viewModel.selectedModelForPreview = nil
                })
            })
            .sheet(isPresented: $showingNewScan) {
                LoadOrtioView()
            }
            .sheet(isPresented: $showingHelp) {
                HelpPageView(showInfo: $showingHelp)
                    .padding()
            }
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func toggleFavorite(for model: ModelsModel.IdentifiableCaptureURL) {
        do {
            let metadata = metadataByURL[model.url.standardizedFileURL]
            let item = LibraryItem(
                capturedURL: model.url,
                metadata: metadata.map {
                    CapturedModelMetadataSnapshot(
                        displayName: $0.normalizedDisplayName,
                        notes: $0.normalizedNotes ?? "",
                        isFavorite: $0.favorite
                    )
                }
            )
            try libraryRepository.toggleFavorite(
                for: item,
                storedModels: [],
                capturedMetadata: capturedMetadata,
                context: modelContext
            )
        } catch {
            viewModel.errorMessage = "Could not update favorite: \(error.localizedDescription)"
        }
    }

    private func presentPreview(for url: URL) {
        switch LibraryPreviewItem.previewableResult(for: url) {
        case .success(let item):
            viewModel.selectedModelForPreview = item
        case .failure(let error):
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - ProfileAvatar

struct ProfileAvatar: View {
    let user: User?
    let scaleEffect: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if let profileImage = user?.profileUIImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.separator, lineWidth: 1))
                    .scaleEffect(scaleEffect)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .scaleEffect(scaleEffect)
            }
        }
        .accessibilityLabel("Profile settings")
    }
}

// MARK: - ModelCard

/// A card displaying a model thumbnail, name, and favorite toggle.
/// Favorites are persisted via UserDefaults keyed by filename.
struct ModelCard: View {
    let model: ModelsModel.IdentifiableCaptureURL
    let metadata: CapturedModelMetadata?
    let onToggleFavorite: () -> Void
    let action: () -> Void
    @State private var thumbnailImage: UIImage?

    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.separator, lineWidth: 0.5)
                        )
                        .frame(height: 120)

                    Group {
                        if let thumbnailImage = thumbnailImage {
                            Image(uiImage: thumbnailImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: "cube.transparent")
                                .font(.title)
                                .foregroundStyle(.secondary)
                                .onAppear(perform: generateThumbnail)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onToggleFavorite) {
                                Image(systemName: isFavorite ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundStyle(isFavorite ? .yellow : .secondary)
                            }
                            .frame(width: 44, height: 44)
                            .sensoryFeedback(.selection, trigger: isFavorite)
                            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .buttonStyle(.plain)

            Text(displayName)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(minHeight: 160)
    }

    private var displayName: String {
        metadata?.normalizedDisplayName ?? model.url.deletingPathExtension().lastPathComponent
    }

    private var isFavorite: Bool {
        metadata?.favorite ?? false
    }

    /// Generates a QuickLook thumbnail for the model file.
    /// Uses the callback-based API since QLThumbnailGenerator doesn't provide async variants.
    private func generateThumbnail() {
        let request = QLThumbnailGenerator.Request(
            fileAt: model.url,
            size: CGSize(width: 120, height: 120),
            scale: UIScreen.main.scale,
            representationTypes: .thumbnail
        )
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { thumbnail, error in
            DispatchQueue.main.async {
                if let thumbnail = thumbnail {
                    self.thumbnailImage = thumbnail.uiImage
                } else {
                    Logger(subsystem: OrtioApp.subsystem, category: "ModelCard")
                        .error("Thumbnail generation error: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}

#Preview {
    ModelsView(viewModel: ModelsViewModel())
}
