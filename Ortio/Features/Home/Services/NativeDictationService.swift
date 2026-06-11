//
//  NativeDictationService.swift
//  Ortio
//
//  Created by OpenAI on 08.04.2026.
//

import AVFoundation
import Foundation
import os
import Speech

/// Transcribes a locally recorded note audio file into text.
protocol NoteDictationServicing {
    func transcribe(audioFileURL: URL) async throws -> String
}

/// Default app-facing dictation service using iOS on-device speech recognition.
struct DefaultNoteDictationService: NoteDictationServicing {
    private let nativeService: NativeDictationService

    init(locale: Locale = .current) {
        self.nativeService = NativeDictationService(locale: locale)
    }

    func transcribe(audioFileURL: URL) async throws -> String {
        try await nativeService.transcribe(audioFileURL: audioFileURL)
    }
}

/// Local speech recognizer wrapper for model-note dictation.
///
/// The service requires speech authorization, a readable audio file, a recognizer
/// for the configured locale, and on-device recognition support. It does not use
/// network transcription or external API keys.
struct NativeDictationService: NoteDictationServicing {
    private let locale: Locale
    private let recognizerFactory: (Locale) -> SFSpeechRecognizer?

    init(
        locale: Locale = .current,
        recognizerFactory: @escaping (Locale) -> SFSpeechRecognizer? = { SFSpeechRecognizer(locale: $0) }
    ) {
        self.locale = locale
        self.recognizerFactory = recognizerFactory
    }

    func transcribe(audioFileURL: URL) async throws -> String {
        let authorizationStatus = await Self.requestSpeechAuthorization()
        guard authorizationStatus == .authorized else {
            throw NativeDictationError.speechRecognitionPermissionDenied
        }

        guard FileManager.default.fileExists(atPath: audioFileURL.path) else {
            throw NativeDictationError.recordingFileMissing
        }

        guard let recognizer = recognizerFactory(locale) else {
            throw NativeDictationError.recognizerUnavailable
        }

        guard recognizer.supportsOnDeviceRecognition else {
            throw NativeDictationError.onDeviceRecognitionUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioFileURL)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = true

        let text = try await Self.recognize(request: request, recognizer: recognizer)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw NativeDictationError.emptyTranscript
        }

        return text
    }

    private static func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private static func recognize(
        request: SFSpeechURLRecognitionRequest,
        recognizer: SFSpeechRecognizer
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let continuationBox = SpeechRecognitionContinuationBox(continuation: continuation)
            let recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuationBox.resume(throwing: NativeDictationError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let result, result.isFinal else { return }

                continuationBox.resume(returning: result.bestTranscription.formattedString)
            }
            continuationBox.recognitionTask = recognitionTask
        }
    }
}

private final class SpeechRecognitionContinuationBox: @unchecked Sendable {
    private let lock = NSLock()
    private var didResume = false
    private let continuation: CheckedContinuation<String, Error>

    var recognitionTask: SFSpeechRecognitionTask?

    init(continuation: CheckedContinuation<String, Error>) {
        self.continuation = continuation
    }

    func resume(returning text: String) {
        guard prepareToResume() else { return }
        continuation.resume(returning: text)
    }

    func resume(throwing error: Error) {
        guard prepareToResume() else { return }
        continuation.resume(throwing: error)
    }

    private func prepareToResume() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard !didResume else { return false }
        didResume = true
        recognitionTask?.cancel()
        recognitionTask = nil
        return true
    }
}

/// Main-actor recorder for temporary note audio and live meter levels.
///
/// `startRecording()` activates the audio session and creates a temporary M4A
/// file. `stopRecording()` returns that file for transcription. `cancelRecording()`
/// removes the temporary file and resets recorder state.
@MainActor
final class VoiceNoteRecorder: NSObject, ObservableObject {
    private static let logger = Logger(subsystem: "com.ortio", category: "VoiceNoteRecorder")
    static let meterSampleCount = 56

    @Published private(set) var isRecording = false
    @Published private(set) var meterLevels: [CGFloat] = Array(repeating: 0.12, count: meterSampleCount)
    @Published private(set) var recordingDuration: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var recordingStartDate: Date?
    private var meterTask: Task<Void, Never>?

    func startRecording() async throws {
        guard !isRecording else { return }

        let hasPermission = await requestPermission()
        guard hasPermission else {
            throw NativeDictationError.microphonePermissionDenied
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ortio-note-\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVEncoderBitRateKey: 128_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        recorder = try AVAudioRecorder(url: tempURL, settings: settings)
        recorder?.isMeteringEnabled = true
        recorder?.record()

        recordingURL = tempURL
        recordingStartDate = Date()
        recordingDuration = 0
        meterLevels = Self.idleMeterLevels
        isRecording = true
        startMetering()
    }

    func stopRecording() throws -> URL {
        guard isRecording else {
            throw NativeDictationError.noRecordingInProgress
        }

        stopMetering()
        recorder?.stop()
        recorder = nil
        isRecording = false

        guard let finishedRecordingURL = recordingURL else {
            throw NativeDictationError.recordingFileMissing
        }

        recordingURL = nil
        recordingStartDate = nil
        recordingDuration = 0
        meterLevels = Self.idleMeterLevels
        try AVAudioSession.sharedInstance().setActive(false)
        return finishedRecordingURL
    }

    func cancelRecording() {
        stopMetering()
        recorder?.stop()
        recorder = nil
        isRecording = false

        if let recordingURL {
            do {
                try FileManager.default.removeItem(at: recordingURL)
            } catch {
                Self.logger.debug("Failed to remove temp recording: \(error.localizedDescription)")
            }
        }

        self.recordingURL = nil
        recordingStartDate = nil
        recordingDuration = 0
        meterLevels = Self.idleMeterLevels
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            Self.logger.debug("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }

    private func startMetering() {
        meterTask?.cancel()
        meterTask = Task { @MainActor [weak self] in
            guard let self else { return }

            while !Task.isCancelled, self.isRecording {
                self.recorder?.updateMeters()
                let averagePower = self.recorder?.averagePower(forChannel: 0) ?? -160
                let normalizedLevel = Self.normalizedLevel(from: averagePower)
                self.pushMeterLevel(normalizedLevel)
                self.recordingDuration = Date().timeIntervalSince(self.recordingStartDate ?? Date())

                try? await Task.sleep(nanoseconds: 55_000_000)
            }
        }
    }

    private func stopMetering() {
        meterTask?.cancel()
        meterTask = nil
    }

    private func pushMeterLevel(_ level: CGFloat) {
        if meterLevels.isEmpty {
            meterLevels = Self.idleMeterLevels
        }

        meterLevels.removeFirst()
        meterLevels.append(level)
    }

    private static func normalizedLevel(from averagePower: Float) -> CGFloat {
        let clampedPower = max(-50, averagePower)
        let normalized = (clampedPower + 50) / 50
        return CGFloat(max(0.22, min(1, normalized)))
    }

    private static var idleMeterLevels: [CGFloat] {
        (0 ..< meterSampleCount).map { index in
            if index.isMultiple(of: 9) {
                return 0.34
            }

            return index.isMultiple(of: 3) ? 0.2 : 0.14
        }
    }

    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
#if os(iOS)
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
#else
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
#endif
        }
    }
}

enum NativeDictationError: LocalizedError {
    case emptyTranscript
    case microphonePermissionDenied
    case onDeviceRecognitionUnavailable
    case recognizerUnavailable
    case recognitionFailed(String)
    case noRecordingInProgress
    case recordingFileMissing
    case speechRecognitionPermissionDenied

    var errorDescription: String? {
        switch self {
        case .emptyTranscript:
            return "No speech was detected in the recording."
        case .microphonePermissionDenied:
            return "Microphone permission is required to dictate notes."
        case .onDeviceRecognitionUnavailable:
            return "On-device speech recognition is not available for the current language."
        case .recognizerUnavailable:
            return "Speech recognition is not available right now."
        case .recognitionFailed(let detail):
            return "Speech recognition failed. \(detail)"
        case .noRecordingInProgress:
            return "No recording is currently in progress."
        case .recordingFileMissing:
            return "The recorded audio file is missing."
        case .speechRecognitionPermissionDenied:
            return "Speech recognition permission is required to dictate notes."
        }
    }
}
