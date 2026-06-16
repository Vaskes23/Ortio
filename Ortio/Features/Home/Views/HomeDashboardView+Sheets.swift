//
//  HomeDashboardView+Sheets.swift
//  Ortio
//
//  ModelNotesSheet with dictation integration.
//

import SwiftUI
import UIKit

// MARK: - ModelNotesDictationState

enum ModelNotesDictationState: Equatable {
    case idle
    case recording
    case transcribing
    case insertedFeedback(previousNotes: String, transcript: String)
    case error(message: String)
}

private enum DictationHaptic {
    case start
    case stop
    case success
    case failure
}

// MARK: - ModelNotesSheet

struct ModelNotesSheet: View {
    let item: LibraryItem
    let onSave: (String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var notes: String
    @StateObject private var recorder = VoiceNoteRecorder()
    @State private var dictationState: ModelNotesDictationState = .idle
    @State private var dictationTask: Task<Void, Never>?
    @State private var shouldRestoreNotesFocusAfterInsert = false
    @FocusState private var isNotesFieldFocused: Bool

    private let dictationService: NoteDictationServicing

    init(
        item: LibraryItem,
        onSave: @escaping (String) -> Bool,
        dictationService: NoteDictationServicing = DefaultNoteDictationService()
    ) {
        self.item = item
        self.onSave = onSave
        self.dictationService = dictationService
        _notes = State(initialValue: item.notes)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OrtioDesignSystem.shellGradient
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    notesEditorSurface
                        .frame(maxWidth: .infinity, minHeight: 250, maxHeight: .infinity, alignment: .top)

                    dictationControl

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 22)
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
                    .disabled(isSaveDisabled)
                }
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            isNotesFieldFocused = true
        }
        .onDisappear {
            dictationTask?.cancel()
            dictationTask = nil
            if recorder.isRecording {
                recorder.cancelRecording()
            }
        }
    }

    private var isSaveDisabled: Bool {
        if case .transcribing = dictationState {
            return true
        }

        return false
    }

    // MARK: - Notes Editor

    private var notesEditorSurface: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(OrtioDesignSystem.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(OrtioDesignSystem.subtleBorder, lineWidth: 1)
                )
                .shadow(color: OrtioDesignSystem.shadow, radius: 24, x: 0, y: 14)

            TextEditor(text: $notes)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(OrtioDesignSystem.Palette.primaryText)
                .scrollContentBackground(.hidden)
                .focused($isNotesFieldFocused)
                .padding(.horizontal, 18)
                .padding(.vertical, 20)

            if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Add notes")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(OrtioDesignSystem.Palette.tertiaryText)
                    .padding(.top, 28)
                    .padding(.leading, 24)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Dictation Control

    @ViewBuilder
    private var dictationControl: some View {
        DictationPillControl(
            state: dictationState,
            meterLevels: recorder.meterLevels,
            duration: recorder.recordingDuration,
            actionSymbolName: dictationActionSymbolName,
            actionAccessibilityLabel: dictationActionAccessibilityLabel,
            actionDisabled: isDictationActionDisabled,
            onAction: handleDictationPrimaryAction,
            onUndo: activeUndoAction
        )
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: dictationState)
        .task(id: insertedFeedbackToken) {
            guard insertedFeedbackToken != nil else { return }
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard case .insertedFeedback = dictationState else { return }

                withAnimation {
                    dictationState = .idle
                }
            }
        }
    }

    private func beginDictation() {
        dictationTask?.cancel()
        dictationTask = Task { @MainActor in
            guard !Task.isCancelled else { return }
            await startDictation()
        }
    }

    private func handleDictationPrimaryAction() {
        switch dictationState {
        case .idle, .error:
            beginDictation()
        case .recording:
            dictationTask?.cancel()
            dictationTask = Task { @MainActor in
                guard !Task.isCancelled else { return }
                await finishDictation()
            }
        case .transcribing, .insertedFeedback:
            break
        }
    }

    private var dictationActionSymbolName: String {
        switch dictationState {
        case .idle:
            "waveform"
        case .recording:
            "stop.fill"
        case .transcribing:
            "ellipsis"
        case .insertedFeedback:
            "checkmark"
        case .error:
            "arrow.clockwise"
        }
    }

    private var dictationActionAccessibilityLabel: String {
        switch dictationState {
        case .idle:
            "Start dictation"
        case .recording:
            "Stop recording"
        case .transcribing:
            "Transcribing"
        case .insertedFeedback:
            "Dictation inserted"
        case .error:
            "Retry dictation"
        }
    }

    private var isDictationActionDisabled: Bool {
        switch dictationState {
        case .transcribing, .insertedFeedback:
            return true
        case .idle, .recording, .error:
            return false
        }
    }

    private var activeUndoAction: (() -> Void)? {
        guard case .insertedFeedback(let previousNotes, _) = dictationState else {
            return nil
        }

        return {
            undoInsertedTranscript(restoring: previousNotes)
        }
    }

    private var insertedFeedbackToken: String? {
        guard case .insertedFeedback(_, let transcript) = dictationState else {
            return nil
        }

        return transcript
    }

    // MARK: - Dictation Lifecycle

    @MainActor
    private func startDictation() async {
        guard canStartDictation else { return }

        do {
            shouldRestoreNotesFocusAfterInsert = isNotesFieldFocused
            isNotesFieldFocused = false
            try await recorder.startRecording()
            playHaptic(.start)

            withAnimation {
                dictationState = .recording
            }
        } catch {
            shouldRestoreNotesFocusAfterInsert = false
            presentDictationError(error)
        }
    }

    @MainActor
    private func finishDictation() async {
        guard case .recording = dictationState else { return }

        withAnimation {
            dictationState = .transcribing
        }

        do {
            let recordedFileURL = try recorder.stopRecording()
            defer { try? FileManager.default.removeItem(at: recordedFileURL) }
            playHaptic(.stop)

            let transcript = try await dictationService.transcribe(audioFileURL: recordedFileURL)
            appendTranscript(transcript)
            playHaptic(.success)

            if shouldRestoreNotesFocusAfterInsert {
                isNotesFieldFocused = true
            }

            shouldRestoreNotesFocusAfterInsert = false
        } catch {
            shouldRestoreNotesFocusAfterInsert = false
            presentDictationError(error)
        }
    }

    private func appendTranscript(_ transcript: String) {
        let cleanTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let previousNotes = notes
        let prefix = previousNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "\n"
        notes = previousNotes + prefix + cleanTranscript

        withAnimation {
            dictationState = .insertedFeedback(previousNotes: previousNotes, transcript: cleanTranscript)
        }
    }

    private func undoInsertedTranscript(restoring previousNotes: String) {
        notes = previousNotes

        withAnimation {
            dictationState = .idle
        }
    }

    private var canStartDictation: Bool {
        switch dictationState {
        case .recording, .transcribing:
            return false
        case .idle, .insertedFeedback, .error:
            return true
        }
    }

    private func presentDictationError(_ error: Error) {
        playHaptic(.failure)

        withAnimation {
            dictationState = .error(message: dictationMessage(for: error))
        }
    }

    private func dictationMessage(for error: Error) -> String {
        switch error {
        case NativeDictationError.microphonePermissionDenied:
            return "Microphone access needed."
        case NativeDictationError.speechRecognitionPermissionDenied:
            return "Speech access needed."
        case NativeDictationError.emptyTranscript:
            return "No speech detected."
        case NativeDictationError.onDeviceRecognitionUnavailable:
            return "Offline dictation unavailable."
        case NativeDictationError.recognizerUnavailable:
            return "Dictation unavailable."
        case NativeDictationError.recognitionFailed:
            return "Could not transcribe."
        default:
            return error.localizedDescription
        }
    }

    private func playHaptic(_ haptic: DictationHaptic) {
#if os(iOS)
        switch haptic {
        case .start:
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.prepare()
            generator.impactOccurred(intensity: 0.85)
        case .stop:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        case .failure:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        }
#endif
    }
}
