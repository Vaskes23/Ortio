//
//  WhisperDictationService.swift
//  Ortio
//
//  Created by OpenAI on 08.04.2026.
//

import AVFoundation
import Foundation
import os

protocol NoteDictationServicing {
    func transcribe(audioFileURL: URL) async throws -> String
}

struct DefaultNoteDictationService: NoteDictationServicing {
    private let whisperService: WhisperDictationService

    init(
        configuration: WhisperServiceConfiguration = .fromEnvironment(),
        session: URLSession = .shared
    ) {
        self.whisperService = WhisperDictationService(configuration: configuration, session: session)
    }

    func transcribe(audioFileURL: URL) async throws -> String {
        try await whisperService.transcribe(audioFileURL: audioFileURL)
    }
}

struct WhisperDictationService: NoteDictationServicing {
    private let configuration: WhisperServiceConfiguration
    private let session: URLSession

    init(
        configuration: WhisperServiceConfiguration = .fromEnvironment(),
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }

    func transcribe(audioFileURL: URL) async throws -> String {
        var request = URLRequest(url: configuration.transcriptionURL)
        request.httpMethod = "POST"

        if let apiKey = configuration.apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let audioData = try Data(contentsOf: audioFileURL)
        request.httpBody = createMultipartBody(
            boundary: boundary,
            model: configuration.model,
            audioData: audioData,
            fileName: audioFileURL.lastPathComponent
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw WhisperDictationError.unreachableServer(
                endpoint: configuration.transcriptionURL,
                detail: error.localizedDescription
            )
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WhisperDictationError.invalidResponse
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown transcription error"
            throw WhisperDictationError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        let transcription = try JSONDecoder().decode(WhisperTranscriptionResponse.self, from: data)
        let text = transcription.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw WhisperDictationError.emptyTranscript
        }

        return text
    }

    private func createMultipartBody(boundary: String, model: String, audioData: Data, fileName: String) -> Data {
        var body = Data()

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.append("\(model)\r\n")

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"task\"\r\n\r\n")
        body.append("transcribe\r\n")

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
        body.append("json\r\n")

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: audio/m4a\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")

        body.append("--\(boundary)--\r\n")
        return body
    }
}

struct WhisperServiceConfiguration {
    enum Source: Equatable {
        case explicitBaseURL
        case defaultLoopback
    }

    let transcriptionURL: URL
    let model: String
    let apiKey: String?
    let source: Source

    static func fromEnvironment(_ environment: [String: String] = ProcessInfo.processInfo.environment) -> WhisperServiceConfiguration {
        let baseURLString = environment["WHISPER_BASE_URL"]
        let apiKey = environment["WHISPER_API_KEY"]
        let model = environment["WHISPER_MODEL"] ?? "turbo"
        let defaultBaseURL = URL(string: "http://127.0.0.1:8080") ?? URL(fileURLWithPath: "/")

        let baseURL: URL
        let source: Source

        if let baseURLString,
           let configuredBaseURL = URL(string: baseURLString) {
            baseURL = configuredBaseURL
            source = .explicitBaseURL
        } else {
            baseURL = defaultBaseURL
            source = .defaultLoopback
        }

        let endpoint = baseURL.appending(path: "v1/audio/transcriptions")

        return WhisperServiceConfiguration(
            transcriptionURL: endpoint,
            model: model,
            apiKey: apiKey,
            source: source
        )
    }
}

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
            throw WhisperDictationError.microphonePermissionDenied
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
            throw WhisperDictationError.noRecordingInProgress
        }

        stopMetering()
        recorder?.stop()
        recorder = nil
        isRecording = false

        guard let finishedRecordingURL = recordingURL else {
            throw WhisperDictationError.recordingFileMissing
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

enum WhisperDictationError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case emptyTranscript
    case unreachableServer(endpoint: URL, detail: String)
    case microphonePermissionDenied
    case noRecordingInProgress
    case recordingFileMissing

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Whisper server returned an invalid response."
        case .serverError(let statusCode, let message):
            return "Whisper server error (\(statusCode)): \(message)"
        case .emptyTranscript:
            return "No speech was detected in the recording."
        case .unreachableServer(let endpoint, let detail):
            return "Could not reach the Whisper server at \(endpoint.host ?? endpoint.absoluteString). \(detail)"
        case .microphonePermissionDenied:
            return "Microphone permission is required to dictate notes."
        case .noRecordingInProgress:
            return "No recording is currently in progress."
        case .recordingFileMissing:
            return "The recorded audio file is missing."
        }
    }
}

private struct WhisperTranscriptionResponse: Decodable {
    let text: String
    let language: String?
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
