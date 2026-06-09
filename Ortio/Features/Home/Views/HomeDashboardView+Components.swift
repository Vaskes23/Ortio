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
    let transition: HomeSearchTransitionCoordinator
    let isSearchFieldFocused: FocusState<Bool>.Binding
    let onSearchTap: () -> Void
    let onCloseSearch: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Ortio")
                .font(.custom("Helvetica-Bold", size: 38))
                .foregroundStyle(.primary)
                .frame(maxWidth: transition.showsTitle ? .infinity : 0, alignment: .leading)
                .opacity(transition.showsTitle ? 1 : 0)
                .scaleEffect(transition.showsTitle ? 1 : 0.92, anchor: .leading)
                .clipped()

            SearchHeaderChrome(
                user: user,
                searchText: $searchText,
                transition: transition,
                isSearchFieldFocused: isSearchFieldFocused,
                onSearchTap: onSearchTap,
                onCloseSearch: onCloseSearch,
                onSettings: onSettings
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: 64)
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: transition.phase)
    }
}

private struct SearchHeaderChrome: View {
    let user: User?
    @Binding var searchText: String
    let transition: HomeSearchTransitionCoordinator
    let isSearchFieldFocused: FocusState<Bool>.Binding
    let onSearchTap: () -> Void
    let onCloseSearch: () -> Void
    let onSettings: () -> Void

    private let compactShellWidth: CGFloat = 96
    private let compactShellHeight: CGFloat = 46
    private let expandedShellHeight: CGFloat = 48
    private let closeBubbleSize: CGFloat = 48

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: transition.showsCloseBubble ? 8 : 0) {
                    chromeContent
                }
            } else {
                chromeContent
            }
        }
    }

    private var chromeContent: some View {
        HStack(spacing: transition.showsCloseBubble ? 8 : 0) {
            searchShell
            closeBubble
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var searchShell: some View {
        HStack(spacing: transition.shellIsExpanded ? 10 : 6) {
            Button(action: onSearchTap) {
                Image(systemName: "magnifyingglass")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(transition.showsSearchFieldContents ? .secondary : .primary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .disabled(!transition.allowsSearchActivation)
            .accessibilityLabel("Search")

            if transition.shellIsExpanded {
                TextField("Search", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused(isSearchFieldFocused)
                    .font(.headline.weight(.medium))
                    .lineLimit(1)
                    .opacity(transition.showsSearchFieldContents ? 1 : 0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipped()
                    .allowsHitTesting(transition.allowsTextFieldInteraction)
                    .accessibilityHidden(!transition.showsSearchFieldContents)
            }

            if transition.showsInlineAvatar {
                Spacer(minLength: 0)

                Button(action: onSettings) {
                    UserAccessoryContent(user: user)
                }
                .buttonStyle(.plain)
                .frame(width: 32, height: 32)
                .opacity(1)
                .scaleEffect(1)
                .allowsHitTesting(true)
                .accessibilityLabel("Open settings")
            }
        }
        .padding(.leading, transition.shellIsExpanded ? 14 : 12)
        .padding(.trailing, transition.showsInlineAvatar ? 6 : 14)
        .frame(height: transition.shellIsExpanded ? expandedShellHeight : compactShellHeight)
        .frame(maxWidth: transition.shellIsExpanded ? .infinity : compactShellWidth, alignment: .trailing)
        .background {
            Capsule(style: .continuous)
                .fill(Color.black.opacity(transition.isTransitioning ? 0.035 : 0))
        }
        .ortioHeaderGlassCapsule()
        .contentShape(Capsule(style: .continuous))
    }

    private var closeBubble: some View {
        Button(action: onCloseSearch) {
            Image(systemName: "xmark")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .opacity(transition.showsCloseGlyph ? 1 : 0)
                .frame(width: closeBubbleSize, height: closeBubbleSize)
        }
        .buttonStyle(.plain)
        .frame(width: transition.showsCloseBubble ? closeBubbleSize : 0, height: closeBubbleSize)
        .background {
            Circle()
                .fill(Color.black.opacity(transition.isTransitioning ? 0.035 : 0))
        }
        .ortioHeaderGlassCircle()
        .contentShape(Circle())
        .opacity(transition.showsCloseBubble ? 1 : 0)
        .scaleEffect(transition.showsCloseBubble ? 1 : 0.88, anchor: .trailing)
        .allowsHitTesting(transition.canBeginClosing)
        .accessibilityLabel("Close search")
        .accessibilityHidden(!transition.showsCloseBubble)
    }
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
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }

    private var userInitials: String {
        let parts = (user?.name ?? "Ortio").split(separator: " ")
        let initials = parts.prefix(2).compactMap(\.first).map(String.init).joined()
        return initials.isEmpty ? "OR" : initials.uppercased()
    }
}

// MARK: - QuickActionsRow

struct QuickActionsRow: View {
    @Binding var selectedFilter: LibraryHomeFilter
    let onOpenTools: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            quickActionsContent
                .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private var quickActionsContent: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 24) {
                quickActionsRow
            }
        } else {
            quickActionsRow
        }
    }

    private var quickActionsRow: some View {
        HStack(spacing: 24) {
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
    }
}

// MARK: - DashboardSection

struct HomeSearchEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No matching models")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Try a different name or clear the query.")
                .foregroundStyle(OrtioDesignSystem.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 18)
    }
}

struct DashboardSection: View {
    let title: String?
    let items: [LibraryItem]
    let showsSearchEmptyState: Bool
    let onSelect: (LibraryItem) -> Void
    let onTogglePin: (LibraryItem) -> Void
    @Binding var expandedNotesItemIDs: Set<String>
    let onChangeName: (LibraryItem) -> Void
    let onAddNotes: (LibraryItem) -> Void
    let onToggleNotes: (LibraryItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Spacer()
                    .frame(height: 24)

                Divider()
                    .overlay(OrtioDesignSystem.subtleBorder.opacity(0.35))

                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.top, 18)
                    .padding(.bottom, 18)
            }

            if items.isEmpty, showsSearchEmptyState {
                HomeSearchEmptyState()
                    .padding(.top, title == nil ? 10 : 0)
            } else {
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
                .padding(.top, title == nil ? 10 : 0)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)

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
