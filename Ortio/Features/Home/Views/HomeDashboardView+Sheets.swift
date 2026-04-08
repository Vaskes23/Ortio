//
//  HomeDashboardView+Sheets.swift
//  GuidedCapture
//
//  Created by OpenAI on 07.04.2026.
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

// MARK: - ModelNotesSheet

struct ModelNotesSheet: View {
    let item: LibraryItem
    let onSave: (String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var notes: String
    @StateObject private var recorder = VoiceNoteRecorder()
    @State private var isTranscribing = false
    @State private var dictationErrorMessage: String?
    @FocusState private var isNotesFieldFocused: Bool

    private let dictationService: WhisperDictationServicing

    init(
        item: LibraryItem,
        onSave: @escaping (String) -> Bool,
        dictationService: WhisperDictationServicing = WhisperDictationService()
    ) {
        self.item = item
        self.onSave = onSave
        self.dictationService = dictationService
        _notes = State(initialValue: item.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
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

                    Button {
                        Task {
                            await handleDictationButtonTapped()
                        }
                    } label: {
                        Label(
                            recorder.isRecording ? "Stop Dictation" : "Dictate with Whisper",
                            systemImage: recorder.isRecording ? "mic.fill" : "mic"
                        )
                        .foregroundStyle(recorder.isRecording ? Color.red : Color.accentColor)
                    }
                    .disabled(isTranscribing)

                    if isTranscribing {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Transcribing audio…")
                                .foregroundStyle(.secondary)
                        }
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
        .alert("Dictation Error", isPresented: dictationErrorPresented) {
            Button("OK", role: .cancel) {
                dictationErrorMessage = nil
            }
        } message: {
            Text(dictationErrorMessage ?? "")
        }
    }

    private var dictationErrorPresented: Binding<Bool> {
        Binding(
            get: { dictationErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    dictationErrorMessage = nil
                }
            }
        )
    }

    @MainActor
    private func handleDictationButtonTapped() async {
        do {
            if recorder.isRecording {
                let recordedFileURL = try recorder.stopRecording()
                isTranscribing = true
                defer { isTranscribing = false }

                let transcript = try await dictationService.transcribe(audioFileURL: recordedFileURL)
                appendTranscript(transcript)
            } else {
                try await recorder.startRecording()
            }
        } catch {
            dictationErrorMessage = error.localizedDescription
        }
    }

    private func appendTranscript(_ transcript: String) {
        let prefix = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "\n"
        notes += "\(prefix)\(transcript)"
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
