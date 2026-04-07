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

// MARK: - ModelEditorDestination

enum ModelEditorDestination: Identifiable {
    case rename(LibraryItem)
    case notes(LibraryItem)

    var id: String {
        switch self {
        case .rename(let item):
            "rename-\(item.id)"
        case .notes(let item):
            "notes-\(item.id)"
        }
    }
}

// MARK: - RenameModelSheet

struct RenameModelSheet: View {
    let item: LibraryItem
    let onSave: (String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var proposedName: String
    @FocusState private var isNameFieldFocused: Bool

    init(item: LibraryItem, onSave: @escaping (String) -> Bool) {
        self.item = item
        self.onSave = onSave
        _proposedName = State(initialValue: item.displayTitle)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Model name", text: $proposedName)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .focused($isNameFieldFocused)
            }
            .navigationTitle("Change Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if onSave(proposedName) {
                            dismiss()
                        }
                    }
                    .disabled(proposedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            isNameFieldFocused = true
        }
    }
}

// MARK: - ModelNotesSheet

struct ModelNotesSheet: View {
    let item: LibraryItem
    let onSave: (String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var notes: String
    @FocusState private var isNotesFieldFocused: Bool

    init(item: LibraryItem, onSave: @escaping (String) -> Bool) {
        self.item = item
        self.onSave = onSave
        _notes = State(initialValue: item.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 180)
                        .focused($isNotesFieldFocused)

                    if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Add notes")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
            }
            .navigationTitle("Add Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if onSave(notes) {
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            isNotesFieldFocused = true
        }
    }
}

// MARK: - EmptyLibraryCard

struct EmptyLibraryCard: View {
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

// MARK: - HomeQuickActionButton

struct HomeQuickActionButton: View {
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

// MARK: - ScanPillButton

struct ScanPillButton: View {
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

// MARK: - HomeToolsSheet

struct HomeToolsSheet: View {
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

// MARK: - ToolActionCard

struct ToolActionCard: View {
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
