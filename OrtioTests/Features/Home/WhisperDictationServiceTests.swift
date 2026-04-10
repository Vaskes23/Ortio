//
//  WhisperDictationServiceTests.swift
//  OrtioTests
//
//  Created by OpenAI on 09.04.2026.
//

import XCTest
@testable import Ortio

final class WhisperDictationServiceTests: XCTestCase {
    func testConfigurationUsesExplicitBaseURLWhenProvided() {
        let configuration = WhisperServiceConfiguration.fromEnvironment([
            "WHISPER_BASE_URL": "https://dictation.example.com",
            "WHISPER_MODEL": "custom-model"
        ])

        XCTAssertEqual(configuration.source, .explicitBaseURL)
        XCTAssertEqual(configuration.model, "custom-model")
        XCTAssertEqual(configuration.transcriptionURL.absoluteString, "https://dictation.example.com/v1/audio/transcriptions")
    }

    func testConfigurationKeepsLoopbackDefaultWithoutBaseURL() {
        let configuration = WhisperServiceConfiguration.fromEnvironment([
            "WHISPER_API_KEY": "test-key"
        ])

        XCTAssertEqual(configuration.source, .defaultLoopback)
        XCTAssertEqual(configuration.apiKey, "test-key")
        XCTAssertEqual(configuration.transcriptionURL.absoluteString, "http://127.0.0.1:8080/v1/audio/transcriptions")
    }

    func testConfigurationDefaultsToSimulatorLoopbackWhenNoSettingsAreProvided() {
        let configuration = WhisperServiceConfiguration.fromEnvironment([:])

        XCTAssertEqual(configuration.source, .defaultLoopback)
        XCTAssertEqual(configuration.model, "turbo")
        XCTAssertEqual(configuration.transcriptionURL.absoluteString, "http://127.0.0.1:8080/v1/audio/transcriptions")
    }
}
