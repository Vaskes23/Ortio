//
//  NativeDictationServiceTests.swift
//  OrtioTests
//
//  Created by OpenAI on 09.04.2026.
//

import XCTest
@testable import Ortio

final class NativeDictationServiceTests: XCTestCase {
    func testOnDeviceUnavailableMessageExplainsOfflineConstraint() {
        XCTAssertEqual(
            NativeDictationError.onDeviceRecognitionUnavailable.errorDescription,
            "On-device speech recognition is not available for the current language."
        )
    }

    func testSpeechPermissionMessageMentionsSpeechRecognition() {
        XCTAssertEqual(
            NativeDictationError.speechRecognitionPermissionDenied.errorDescription,
            "Speech recognition permission is required to dictate notes."
        )
    }

    func testRecordingFileMissingMessageIsPreservedForRecorderFailures() {
        XCTAssertEqual(
            NativeDictationError.recordingFileMissing.errorDescription,
            "The recorded audio file is missing."
        )
    }
}
