//
//  CaptureUtilitiesTests.swift
//  GuidedCaptureTests
//
//  Created by OpenAI on 08.04.2026.
//

import XCTest
import RealityKit
@testable import Ortio

final class CaptureUtilitiesTests: XCTestCase {
    func testParseShotIdReturnsValueForValidImageName() {
        let url = URL(fileURLWithPath: "/tmp/IMG_0042.HEIC")

        XCTAssertEqual(CaptureFolderManager.parseShotId(url: url), 42)
    }

    func testParseShotIdReturnsNilForInvalidPrefix() {
        let url = URL(fileURLWithPath: "/tmp/PIC_0042.HEIC")

        XCTAssertNil(CaptureFolderManager.parseShotId(url: url))
    }

    func testImageIdStringUsesExpectedPrefixAndPadding() {
        XCTAssertEqual(CaptureFolderManager.imageIdString(for: 7), "IMG_0007")
    }

    func testShotFileInfoInitializesForValidCaptureFile() {
        let info = ShotFileInfo(url: URL(fileURLWithPath: "/tmp/IMG_0010.HEIC"))

        XCTAssertEqual(info?.id, 10)
    }
}

final class UntilProcessingCompleteFilterTests: XCTestCase {
    func testNextStopsAfterProcessingComplete() async {
        let stream = AsyncStream<PhotogrammetrySession.Output> { continuation in
            continuation.yield(.processingComplete)
            continuation.yield(.processingCancelled)
            continuation.finish()
        }

        var filter = UntilProcessingCompleteFilter(input: stream)
        let first = await filter.next()
        let second = await filter.next()

        if case .processingComplete? = first {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .processingComplete")
        }
        XCTAssertNil(second)
    }
}
