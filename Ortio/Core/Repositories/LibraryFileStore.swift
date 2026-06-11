//
//  LibraryFileStore.swift
//  Ortio
//
//  Created by OpenAI on 08.04.2026.
//

import Foundation
import os

/// Concrete folder layout used by an Object Capture session.
struct CaptureDirectoryLayout: Sendable, Equatable {
    let rootScanFolder: URL
    let imagesFolder: URL
    let snapshotsFolder: URL
    let modelsFolder: URL
}

/// Result of copying an imported model into Ortio-managed storage.
struct ImportedModelFile: Sendable, Equatable {
    let destinationURL: URL
    let fileSize: Double
    let fileDate: Date
}

/// Actor boundary for all library filesystem operations.
///
/// Repository and view-model code should depend on this protocol when tests need
/// deterministic filesystem behavior. Implementations own document-directory
/// paths, scan folder creation, import copies, imported directory deletion, and
/// transient capture cleanup.
protocol LibraryFileStoreProtocol: Actor {
    func capturedModelURLs() throws -> [URL]
    func createNewScanDirectory() -> URL?
    func prepareCaptureDirectories(in rootScanFolder: URL) -> CaptureDirectoryLayout?
    func missingImportedModelURLs(in urls: [URL]) -> Set<URL>
    func importFile(from sourceURL: URL) throws -> ImportedModelFile
    func deleteImportedModelDirectory(containing fileURL: URL) throws
    func removeTransientCaptureArtifacts(in rootScanFolder: URL, preservingModels: Bool)
}

/// Production file store for `Documents/Scans` and `Documents/Imports`.
///
/// Methods run on the actor to serialize filesystem access. The actor does not
/// mutate SwiftData; callers receive URLs or metadata and save records through
/// repository code on the main actor.
actor LibraryFileStore: LibraryFileStoreProtocol {
    private static let logger = Logger(subsystem: "com.ortio", category: "LibraryFileStore")
    private let fileManager: FileManagerProtocol
    private let now: () -> Date

    init(fileManager: FileManagerProtocol = FileManager.default, now: @escaping () -> Date = Date.init) {
        self.fileManager = fileManager
        self.now = now
    }

    func capturedModelURLs() throws -> [URL] {
        let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let scansFolder = documentsDirectory.appendingPathComponent(PathConstants.scans, isDirectory: true)
        let sessionDirectories: [URL]
        do {
            sessionDirectories = try fileManager.contentsOfDirectory(
                at: scansFolder,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
        } catch CocoaError.fileReadNoSuchFile {
            return []
        } catch {
            throw error
        }
        var allModelURLs: [URL] = []
        for sessionDirectory in sessionDirectories {
            let modelsFolder = sessionDirectory.appendingPathComponent(PathConstants.models, isDirectory: true)
            if fileManager.fileExists(atPath: modelsFolder.path, isDirectory: nil) {
                let modelURLs = try fileManager.contentsOfDirectory(at: modelsFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                allModelURLs.append(contentsOf: modelURLs)
            }
        }
        return allModelURLs
    }

    func createNewScanDirectory() -> URL? {
        guard let capturesFolder = rootScansFolder() else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let newCaptureDir = capturesFolder.appendingPathComponent(formatter.string(from: now()), isDirectory: true)
        do {
            try fileManager.createDirectory(atPath: newCaptureDir.path, withIntermediateDirectories: true, attributes: nil)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var mutableURL = newCaptureDir
            do {
                try mutableURL.setResourceValues(values)
            } catch {
                Self.logger.warning("Failed to exclude scan directory from backup: \(error.localizedDescription)")
            }
        } catch {
            return nil
        }
        var isDirectory = ObjCBool(false)
        let exists = fileManager.fileExists(atPath: newCaptureDir.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue ? newCaptureDir : nil
    }

    func prepareCaptureDirectories(in rootScanFolder: URL) -> CaptureDirectoryLayout? {
        let imagesFolder = rootScanFolder.appendingPathComponent(PathConstants.images, isDirectory: true)
        let snapshotsFolder = rootScanFolder.appendingPathComponent(PathConstants.snapshots, isDirectory: true)
        let modelsFolder = rootScanFolder.appendingPathComponent(PathConstants.models, isDirectory: true)
        guard createDirectoryIfNeeded(at: imagesFolder),
              createDirectoryIfNeeded(at: snapshotsFolder),
              createDirectoryIfNeeded(at: modelsFolder) else { return nil }
        return CaptureDirectoryLayout(rootScanFolder: rootScanFolder, imagesFolder: imagesFolder, snapshotsFolder: snapshotsFolder, modelsFolder: modelsFolder)
    }

    func missingImportedModelURLs(in urls: [URL]) -> Set<URL> {
        Set(urls.filter { !fileManager.fileExists(atPath: $0.standardizedFileURL.path, isDirectory: nil) })
    }

    func importFile(from sourceURL: URL) throws -> ImportedModelFile {
        let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let importsDirectory = documentsDirectory.appendingPathComponent(PathConstants.imports, isDirectory: true)
        guard createDirectoryIfNeeded(at: importsDirectory) else { throw CocoaError(.fileWriteUnknown) }

        let creationDate = try sourceURL.resourceValues(forKeys: [.creationDateKey]).creationDate
        let folderName = LibraryRepository.createUniqueFolderName(from: creationDate)
        let modelFolderURL = importsDirectory.appendingPathComponent(folderName, isDirectory: true)
        guard createDirectoryIfNeeded(at: modelFolderURL) else { throw CocoaError(.fileWriteUnknown) }

        let destinationURL = modelFolderURL.appendingPathComponent(sourceURL.lastPathComponent)
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        let fileSize = try fileManager.attributesOfItem(atPath: destinationURL.path)[.size] as? Double ?? 0
        return ImportedModelFile(destinationURL: destinationURL, fileSize: fileSize, fileDate: creationDate ?? now())
    }

    func deleteImportedModelDirectory(containing fileURL: URL) throws {
        let parent = fileURL.deletingLastPathComponent()
        if fileManager.fileExists(atPath: parent.path, isDirectory: nil) {
            try fileManager.removeItem(at: parent)
        }
    }

    func removeTransientCaptureArtifacts(in rootScanFolder: URL, preservingModels: Bool) {
        if preservingModels {
            removeItemIfExists(at: rootScanFolder.appendingPathComponent(PathConstants.images, isDirectory: true))
            removeItemIfExists(at: rootScanFolder.appendingPathComponent(PathConstants.snapshots, isDirectory: true))
        } else {
            removeItemIfExists(at: rootScanFolder)
        }
    }

    private func rootScansFolder() -> URL? {
        guard let documentsFolder = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return nil }
        let scansFolder = documentsFolder.appendingPathComponent(PathConstants.scans, isDirectory: true)
        guard createDirectoryIfNeeded(at: scansFolder) else { return nil }
        return scansFolder
    }

    private func createDirectoryIfNeeded(at url: URL) -> Bool {
        var isDirectory = ObjCBool(false)
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) { return isDirectory.boolValue }
        do {
            try fileManager.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            return false
        }
    }

    private func removeItemIfExists(at url: URL) {
        guard fileManager.fileExists(atPath: url.path, isDirectory: nil) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            Self.logger.warning("Failed to remove item at \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
}
