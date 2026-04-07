//
//  GlobalSearchView.swift
//  GuidedCapture
//
//  Created by OpenAI on 07.04.2026.
//

import SwiftUI

struct GlobalSearchView: View {
    @Bindable var viewModel: GlobalSearchViewModel
    let onDismiss: () -> Void

    @FocusState private var isSearchFieldFocused: Bool
    @State private var previewItem: LibraryPreviewItem?

    var body: some View {
        ZStack {
            OrtioDesignSystem.shellGradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
                SearchBar(text: $viewModel.searchText, onDismiss: onDismiss)
                    .focused($isSearchFieldFocused)

                if viewModel.filteredItems.isEmpty {
                    SearchEmptyState()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            if !viewModel.capturedResults.isEmpty {
                                SearchSection(
                                    title: "Captured",
                                    items: viewModel.capturedResults,
                                    onSelect: selectItem
                                )
                            }

                            if !viewModel.importedResults.isEmpty {
                                SearchSection(
                                    title: "Imported",
                                    items: viewModel.importedResults,
                                    onSelect: selectItem
                                )
                            }
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .onAppear {
            isSearchFieldFocused = true
        }
        .sheet(item: $previewItem) { item in
            ModelView(modelFile: item.url) {
                previewItem = nil
            }
        }
    }

    private func selectItem(_ item: LibraryItem) {
        previewItem = LibraryPreviewItem(url: item.url)
    }
}

private struct SearchBar: View {
    @Binding var text: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search models", text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(OrtioDesignSystem.elevatedSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(OrtioDesignSystem.subtleBorder, lineWidth: 1)
            )

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.headline.weight(.semibold))
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(OrtioDesignSystem.elevatedSurface))
                    .overlay(Circle().stroke(OrtioDesignSystem.subtleBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .accessibilityLabel("Close search")
        }
    }
}

private struct SearchSection: View {
    let title: String
    let items: [LibraryItem]
    let onSelect: (LibraryItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            VStack(spacing: 10) {
                ForEach(items) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: item.source.symbolName)
                                .font(.headline)
                                .frame(width: 18)
                                .foregroundStyle(.primary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)

                                Text(item.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(OrtioDesignSystem.mutedText)
                            }

                            Spacer()

                            if item.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .ortioCardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct SearchEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No matching models")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Try a different name, or return to the dashboard to start a new scan or import a file.")
                .foregroundStyle(OrtioDesignSystem.mutedText)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ortioCardStyle()
    }
}
