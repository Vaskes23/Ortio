//
//  HomeDashboardView+Components.swift
//  GuidedCapture
//
//  Created by OpenAI on 07.04.2026.
//

import SwiftData
import SwiftUI

// MARK: - DashboardHeader

struct DashboardHeader: View {
    let user: User?
    @Binding var searchText: String
    let searchPresentationState: HomeSearchPresentationState
    let namespace: Namespace.ID
    let isSearchFieldFocused: FocusState<Bool>.Binding
    let onSearchTap: () -> Void
    let onCloseSearch: () -> Void
    let onSettings: () -> Void

    private var isExpanded: Bool {
        switch searchPresentationState {
        case .expanding, .active:
            return true
        case .idle, .collapsing:
            return false
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Ortio")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .frame(maxWidth: isExpanded ? 0 : .infinity, alignment: .leading)
                .opacity(isExpanded ? 0 : 1)
                .scaleEffect(isExpanded ? 0.92 : 1, anchor: .leading)
                .clipped()

            if isExpanded {
                ExpandedSearchHeaderControls(
                    searchText: $searchText,
                    namespace: namespace,
                    isSearchFieldFocused: isSearchFieldFocused,
                    onCloseSearch: onCloseSearch
                )
            } else {
                CompactSearchHeaderControls(
                    user: user,
                    namespace: namespace,
                    onSearchTap: onSearchTap,
                    onSettings: onSettings
                )
            }
        }
        .frame(height: 58)
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: isExpanded)
    }
}

private struct CompactSearchHeaderControls: View {
    let user: User?
    let namespace: Namespace.ID
    let onSearchTap: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onSearchTap) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .frame(width: 58, height: 50)
                .matchedGeometryEffect(id: "search-pill", in: namespace)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Search")

            Rectangle()
                .fill(OrtioDesignSystem.subtleBorder)
                .frame(width: 1, height: 24)

            Button(action: onSettings) {
                UserAccessoryContent(user: user)
                    .frame(width: 52, height: 50)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open settings")
            .matchedGeometryEffect(id: "search-accessory", in: namespace)
        }
        .ortioHeaderGlassCapsule()
    }

    private struct UserAccessoryContent: View {
        let user: User?

        var body: some View {
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
        }

        private var userInitials: String {
            let parts = (user?.name ?? "Ortio").split(separator: " ")
            let initials = parts.prefix(2).compactMap(\.first).map(String.init).joined()
            return initials.isEmpty ? "OR" : initials.uppercased()
        }
    }
}

private struct ExpandedSearchHeaderControls: View {
    @Binding var searchText: String
    let namespace: Namespace.ID
    let isSearchFieldFocused: FocusState<Bool>.Binding
    let onCloseSearch: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Search", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused(isSearchFieldFocused)
                    .font(.headline.weight(.medium))
            }
            .padding(.horizontal, 18)
            .frame(height: 52)
            .frame(maxWidth: .infinity, alignment: .leading)
            .matchedGeometryEffect(id: "search-pill", in: namespace)
            .ortioHeaderGlassCapsule()

            Button(action: onCloseSearch) {
                Image(systemName: "xmark")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 52, height: 52)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .matchedGeometryEffect(id: "search-accessory", in: namespace)
            .ortioHeaderGlassCircle()
            .accessibilityLabel("Close search")
        }
    }
}

// MARK: - QuickActionsRow

struct QuickActionsRow: View {
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

// MARK: - DashboardSection

struct DashboardSection: View {
    let title: String
    let items: [LibraryItem]
    let onSelect: (LibraryItem) -> Void
    let onTogglePin: (LibraryItem) -> Void
    @Binding var expandedNotesItemIDs: Set<String>
    let onChangeName: (LibraryItem) -> Void
    let onAddNotes: (LibraryItem) -> Void
    let onToggleNotes: (LibraryItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Divider()
                .overlay(OrtioDesignSystem.subtleBorder)

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            VStack(spacing: 18) {
                ForEach(items) { item in
                    LibraryCard(
                        item: item,
                        onSelect: { onSelect(item) },
                        onTogglePin: { onTogglePin(item) },
                        isNotesExpanded: expandedNotesItemIDs.contains(item.id),
                        onChangeName: { onChangeName(item) },
                        onAddNotes: { onAddNotes(item) },
                        onToggleNotes: { onToggleNotes(item) }
                    )
                }
            }
        }
    }
}

// MARK: - LibraryCard

struct LibraryCard: View {
    let item: LibraryItem
    let onSelect: () -> Void
    let onTogglePin: () -> Void
    let isNotesExpanded: Bool
    let onChangeName: () -> Void
    let onAddNotes: () -> Void
    let onToggleNotes: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                Button(action: onSelect) {
                    HStack(spacing: 14) {
                        Text(item.displayTitle)
                            .font(.system(size: 19, weight: .regular))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                HStack(spacing: 2) {
                    Button(action: onToggleNotes) {
                        Image(systemName: "note.text")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .opacity(isNotesExpanded || !item.notes.isEmpty ? 0.9 : 0.18)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.notes.isEmpty ? "Show notes" : "Show notes for \(item.displayTitle)")

                    Button(action: onTogglePin) {
                        Image(systemName: "pin.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .opacity(item.isFavorite ? 0.9 : 0.18)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.isFavorite ? "Unpin design" : "Pin design")
                }
            }

            if isNotesExpanded {
                Text(item.notes.isEmpty ? "No notes added." : item.notes)
                    .font(.subheadline)
                    .foregroundStyle(item.notes.isEmpty ? .tertiary : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 1)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: isNotesExpanded)
        .contextMenu {
            Button("Change Name", systemImage: "pencil") {
                onChangeName()
            }

            Button("Add Notes", systemImage: "note.text") {
                onAddNotes()
            }

            ShareLink(item: item.url) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}
