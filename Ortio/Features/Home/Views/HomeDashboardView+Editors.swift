//
//  HomeDashboardView+Editors.swift
//  Ortio
//

import SwiftUI

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
