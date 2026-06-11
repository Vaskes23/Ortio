//
//  GlobalSearchView.swift
//  Ortio
//
//  Created by OpenAI on 07.04.2026.
//

import SwiftUI

struct GlobalSearchContent: View {
    @Bindable var viewModel: GlobalSearchViewModel
    let onSelect: (LibraryItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.filteredItems.isEmpty {
                SearchEmptyState()
                    .padding(.top, 10)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(viewModel.filteredItems.enumerated()), id: \.element.id) { index, item in
                        SearchResultRow(
                            item: item,
                            onSelect: { onSelect(item) }
                        )
                        .padding(.top, index == 0 ? 10 : 0)
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }
}

private struct SearchEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No matching models")
                .font(.title3.weight(.semibold))
                .foregroundStyle(OrtioDesignSystem.Palette.primaryText)

            Text("Try a different name or clear the query.")
                .foregroundStyle(OrtioDesignSystem.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 18)
    }
}

private struct SearchResultRow: View {
    let item: LibraryItem
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(item.displayTitle)
                    .font(.system(size: 21, weight: .regular))
                    .foregroundStyle(OrtioDesignSystem.Palette.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)

                if item.isFavorite {
                    Image(systemName: "pin.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OrtioDesignSystem.Palette.secondaryText)
                }
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
