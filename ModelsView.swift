//
//  ModelsView.swift
//  ModelCapture
//
//  Created by Matyas Vascak on 23.12.2023.
//

import Foundation
import SwiftUI
import SwiftData
import QuickLookThumbnailing

struct ModelsView: View {
    @State private var searchText = ""
    @ObservedObject var viewModel: ModelsViewModel
    @Query var users: [User]
    
    @State private var scaleEffect: CGFloat = 1.0
    @State private var navigateToSettings = false
    @State private var showingNewScan = false
    @State private var showingHelp = false

    var user: User? {
        users.first
    }

    let columns = [GridItem(.adaptive(minimum: 120), spacing: 16)]

    var filteredModels: [ModelsModel.IdentifiableCaptureURL] {
        let usdzModels = viewModel.models.filter { $0.url.pathExtension == "usdz" }
        guard !searchText.isEmpty else { return usdzModels }
        return usdzModels.filter { model in
            model.url.lastPathComponent.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(filteredModels) { model in
                        ModelCard(model: model) {
                            viewModel.selectedModelForPreview = model
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Models")
            .searchable(text: $searchText, prompt: "Search models or notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileAvatar(user: user, scaleEffect: scaleEffect) {
                        withAnimation(.spring()) {
                            scaleEffect = 1.5
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.spring()) {
                                scaleEffect = 1.0
                                navigateToSettings = true
                            }
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: {
                        showingNewScan = true
                    }) {
                        Label("New Scan", systemImage: "camera.viewfinder")
                    }
                    .sensoryFeedback(.selection, trigger: showingNewScan)
                    
                    Spacer()
                    
                    Button(action: {
                        showingHelp = true
                    }) {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                    .sensoryFeedback(.selection, trigger: showingHelp)
                }
            }
            .onAppear(perform: viewModel.loadModelsFromDirectories)
            .sheet(item: $viewModel.selectedModelForPreview, onDismiss: {
                viewModel.selectedModelForPreview = nil
            }) { item in
                ModelView(modelFile: item.url, endCaptureCallback: {
                    viewModel.selectedModelForPreview = nil
                })
            }
            .sheet(isPresented: $showingNewScan) {
                LoadGuidedCaptureView()
            }
            .sheet(isPresented: $showingHelp) {
                HelpPageView(showInfo: $showingHelp)
                    .padding()
            }
            .background(
                NavigationLink(destination: SettingsView(), isActive: $navigateToSettings) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }
}

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

struct ModelCard: View {
    let model: ModelsModel.IdentifiableCaptureURL
    let action: () -> Void
    @State private var thumbnailImage: UIImage?
    @State private var isFavorite = false
    
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
                            Button(action: {
                                isFavorite.toggle()
                            }) {
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
            
            Text(model.url.deletingPathExtension().lastPathComponent)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(minHeight: 160)
    }
    
    private func generateThumbnail() {
        let request = QLThumbnailGenerator.Request(
            fileAt: model.url,
            size: CGSize(width: 120, height: 120),
            scale: UIScreen.main.scale,
            representationTypes: .thumbnail
        )
        let generator = QLThumbnailGenerator.shared
        generator.generateBestRepresentation(for: request) { (thumbnail, error) in
            DispatchQueue.main.async {
                if let thumbnail = thumbnail {
                    self.thumbnailImage = thumbnail.uiImage
                } else {
                    print("Thumbnail generation error: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}



#Preview {
    ModelsView(viewModel: ModelsViewModel())
}
