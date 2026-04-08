import Testing
import Foundation
import RealityKit
@testable import Ortio

@Suite("Capture Utilities")
struct CaptureUtilitiesTests {
    @Test
    func parseShotIdReturnsValueForValidImageName() {
        let url = URL(fileURLWithPath: "/tmp/IMG_0042.HEIC")

        let id = CaptureFolderManager.parseShotId(url: url)

        #expect(id == 42)
    }

    @Test
    func parseShotIdReturnsNilForInvalidPrefix() {
        let url = URL(fileURLWithPath: "/tmp/PIC_0042.HEIC")

        let id = CaptureFolderManager.parseShotId(url: url)

        #expect(id == nil)
    }

    @Test
    func parseShotIdReturnsNilForNonNumericSuffix() {
        let url = URL(fileURLWithPath: "/tmp/IMG_00AB.HEIC")

        let id = CaptureFolderManager.parseShotId(url: url)

        #expect(id == nil)
    }

    @Test
    func imageIdStringUsesExpectedPrefixAndPadding() {
        let imageIDString = CaptureFolderManager.imageIdString(for: 7)
        #expect(imageIDString == "IMG_0007")
    }

    @Test
    func heicImageUrlBuildsExpectedPath() {
        let outputDirectory = URL(fileURLWithPath: "/tmp/Scans")

        let imageURL = CaptureFolderManager.heicImageUrl(in: outputDirectory, id: 12)

        #expect(imageURL.lastPathComponent == "IMG_0012.HEIC")
        #expect(imageURL.deletingLastPathComponent().path == outputDirectory.path)
    }

    @Test
    func shotFileInfoInitializesForValidCaptureFile() {
        let info = ShotFileInfo(url: URL(fileURLWithPath: "/tmp/IMG_0010.HEIC"))

        #expect(info != nil)
        #expect(info?.id == 10)
    }

    @Test
    func shotFileInfoReturnsNilForInvalidCaptureFile() {
        let info = ShotFileInfo(url: URL(fileURLWithPath: "/tmp/not-a-shot.HEIC"))

        #expect(info == nil)
    }
}

@Suite("UntilProcessingCompleteFilter")
struct UntilProcessingCompleteFilterTests {
    @Test
    func nextStopsAfterProcessingComplete() async {
        let stream = AsyncStream<PhotogrammetrySession.Output> { continuation in
            continuation.yield(.processingComplete)
            continuation.yield(.processingCancelled)
            continuation.finish()
        }

        var filter = UntilProcessingCompleteFilter(input: stream)
        let first = await filter.next()
        let second = await filter.next()

        if case .processingComplete? = first {
            #expect(Bool(true))
        } else {
            Issue.record("Expected first emitted output to be .processingComplete")
        }
        #expect(second == nil)
    }

    @Test
    func nextStopsAfterProcessingCancelled() async {
        let stream = AsyncStream<PhotogrammetrySession.Output> { continuation in
            continuation.yield(.processingCancelled)
            continuation.yield(.processingComplete)
            continuation.finish()
        }

        var filter = UntilProcessingCompleteFilter(input: stream)
        let first = await filter.next()
        let second = await filter.next()

        if case .processingCancelled? = first {
            #expect(Bool(true))
        } else {
            Issue.record("Expected first emitted output to be .processingCancelled")
        }
        #expect(second == nil)
    }

    @Test
    func nextReturnsNilWhenInputSequenceEnds() async {
        let stream = AsyncStream<PhotogrammetrySession.Output> { continuation in
            continuation.finish()
        }

        var filter = UntilProcessingCompleteFilter(input: stream)
        let next = await filter.next()

        #expect(next == nil)
    }
}
