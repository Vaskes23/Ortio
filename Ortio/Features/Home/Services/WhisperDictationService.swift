//
//  WhisperDictationService.swift
//  Ortio
//
//  Created by OpenAI on 08.04.2026.
//

import AVFoundation
import Foundation

protocol WhisperDictationServicing {
    func transcribe(audioFileURL: URL) async throws -> String
}

struct WhisperDictationService: WhisperDictationServicing {
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

        let (data, response) = try await session.data(for: request)
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
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: audio/m4a\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")

        body.append("--\(boundary)--\r\n")
        return body
    }
}

struct WhisperServiceConfiguration {
    let transcriptionURL: URL
    let model: String
    let apiKey: String?

    static func fromEnvironment() -> WhisperServiceConfiguration {
        let environment = ProcessInfo.processInfo.environment
        let baseURLString = environment["WHISPER_BASE_URL"] ?? "http://127.0.0.1:8080"
        let defaultBaseURL = URL(string: "http://127.0.0.1:8080") ?? URL(fileURLWithPath: "/")
        let baseURL = URL(string: baseURLString) ?? defaultBaseURL
        let endpoint = baseURL.appending(path: "v1/audio/transcriptions")
        let model = environment["WHISPER_MODEL"] ?? "whisper-1"
        let apiKey = environment["WHISPER_API_KEY"]

        return WhisperServiceConfiguration(
            transcriptionURL: endpoint,
            model: model,
            apiKey: apiKey
        )
    }
}

@MainActor
final class VoiceNoteRecorder: NSObject, ObservableObject {
    @Published private(set) var isRecording = false

    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?

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
        recorder?.record()

        recordingURL = tempURL
        isRecording = true
    }

    func stopRecording() throws -> URL {
        guard isRecording else {
            throw WhisperDictationError.noRecordingInProgress
        }

        recorder?.stop()
        recorder = nil
        isRecording = false

        guard let recordingURL else {
            throw WhisperDictationError.recordingFileMissing
        }

        try AVAudioSession.sharedInstance().setActive(false)
        return recordingURL
    }

    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

enum WhisperDictationError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case emptyTranscript
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
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
