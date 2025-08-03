//
//  FileManagerMocks.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

@testable import Ortio

import Foundation

class MockFileManager: FileManagerProtocol {
    var contentsOfDirectoryStub: ((URL, [URLResourceKey]?, FileManager.DirectoryEnumerationOptions) throws -> [URL])?
    var fileExistsStub: ((String, UnsafeMutablePointer<ObjCBool>?) -> Bool)?
    var urlStub: ((FileManager.SearchPathDirectory, FileManager.SearchPathDomainMask, URL?, Bool) throws -> URL)?
    var createDirectoryStub: ((String, Bool, [FileAttributeKey: Any]?) throws -> Void)?
    var attributesOfItemStub: ((String) throws -> [FileAttributeKey: Any])?
    var copyItemStub: ((URL, URL) throws -> Void)?
    
    // Additional properties for more complex testing scenarios
    var removeItemStub: ((URL) throws -> Void)?
    var moveItemStub: ((URL, URL) throws -> Void)?
    var linkItemStub: ((URL, URL) throws -> Void)?
    var trashItemStub: ((URL) throws -> URL)?
    
    // Properties to track method calls
    var contentsOfDirectoryCallCount = 0
    var fileExistsCallCount = 0
    var urlCallCount = 0
    var createDirectoryCallCount = 0
    var attributesOfItemCallCount = 0
    var copyItemCallCount = 0
    
    // Properties to store last called parameters
    var lastContentsOfDirectoryURL: URL?
    var lastFileExistsPath: String?
    var lastURLCallParameters: (directory: FileManager.SearchPathDirectory, domain: FileManager.SearchPathDomainMask, url: URL?, shouldCreate: Bool)?
    var lastCreateDirectoryParameters: (path: String, withIntermediateDirectories: Bool, attributes: [FileAttributeKey: Any]?)?
    var lastAttributesOfItemPath: String?
    var lastCopyItemParameters: (srcURL: URL, dstURL: URL)?
    
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL] {
        contentsOfDirectoryCallCount += 1
        lastContentsOfDirectoryURL = url
        return try contentsOfDirectoryStub?(url, keys, mask) ?? []
    }

    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        fileExistsCallCount += 1
        lastFileExistsPath = path
        return fileExistsStub?(path, isDirectory) ?? false
    }

    func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask, appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL {
        urlCallCount += 1
        lastURLCallParameters = (directory, domain, url, shouldCreate)
        return try urlStub?(directory, domain, url, shouldCreate) ?? URL(fileURLWithPath: "")
    }

    func createDirectory(atPath path: String, withIntermediateDirectories: Bool, attributes: [FileAttributeKey: Any]?) throws {
        createDirectoryCallCount += 1
        lastCreateDirectoryParameters = (path, withIntermediateDirectories, attributes)
        try createDirectoryStub?(path, withIntermediateDirectories, attributes)
    }

    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        attributesOfItemCallCount += 1
        lastAttributesOfItemPath = path
        return try attributesOfItemStub?(path) ?? [:]
    }

    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        copyItemCallCount += 1
        lastCopyItemParameters = (srcURL, dstURL)
        try copyItemStub?(srcURL, dstURL)
    }
    
    // MARK: - Reset Methods
    
    func resetCallCounts() {
        contentsOfDirectoryCallCount = 0
        fileExistsCallCount = 0
        urlCallCount = 0
        createDirectoryCallCount = 0
        attributesOfItemCallCount = 0
        copyItemCallCount = 0
    }
    
    func resetLastCalledParameters() {
        lastContentsOfDirectoryURL = nil
        lastFileExistsPath = nil
        lastURLCallParameters = nil
        lastCreateDirectoryParameters = nil
        lastAttributesOfItemPath = nil
        lastCopyItemParameters = nil
    }
    
    func resetAll() {
        resetCallCounts()
        resetLastCalledParameters()
        contentsOfDirectoryStub = nil
        fileExistsStub = nil
        urlStub = nil
        createDirectoryStub = nil
        attributesOfItemStub = nil
        copyItemStub = nil
        removeItemStub = nil
        moveItemStub = nil
        linkItemStub = nil
        trashItemStub = nil
    }
}

// MARK: - MockFileManager Convenience Extensions

extension MockFileManager {
    
    /// Convenience method to set up a successful directory listing
    func setupSuccessfulDirectoryListing(at url: URL, returning contents: [URL]) {
        contentsOfDirectoryStub = { directoryURL, keys, mask in
            if directoryURL == url {
                return contents
            }
            return []
        }
    }
    
    /// Convenience method to set up a successful URL retrieval
    func setupURL(for directory: FileManager.SearchPathDirectory, returning url: URL) {
        urlStub = { searchDirectory, domain, appropriateFor, shouldCreate in
            if searchDirectory == directory {
                return url
            }
            throw NSError(domain: "MockFileManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Directory not found"])
        }
    }
    
    /// Convenience method to set up a successful directory creation
    func setupSuccessfulDirectoryCreation() {
        createDirectoryStub = { path, withIntermediateDirectories, attributes in
            // Success - do nothing
        }
    }
    
    /// Convenience method to set up a failed directory creation
    func setupFailedDirectoryCreation(with error: Error) {
        createDirectoryStub = { path, withIntermediateDirectories, attributes in
            throw error
        }
    }
    
    /// Convenience method to set up successful file attributes
    func setupFileAttributes(at path: String, attributes: [FileAttributeKey: Any]) {
        attributesOfItemStub = { filePath in
            if filePath == path {
                return attributes
            }
            throw NSError(domain: "MockFileManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "File not found"])
        }
    }
    
    /// Convenience method to set up successful file copy
    func setupSuccessfulFileCopy() {
        copyItemStub = { srcURL, dstURL in
            // Success - do nothing
        }
    }
    
    /// Convenience method to set up a failed file copy
    func setupFailedFileCopy(with error: Error) {
        copyItemStub = { srcURL, dstURL in
            throw error
        }
    }
    
    /// Convenience method to create a realistic file system structure
    func setupRealisticFileSystem() {
        let documentsURL = URL(fileURLWithPath: "/path/to/Documents")
        let scansFolderURL = documentsURL.appendingPathComponent("Scans")
        let session1URL = scansFolderURL.appendingPathComponent("Session1")
        let session2URL = scansFolderURL.appendingPathComponent("Session2")
        let models1URL = session1URL.appendingPathComponent("Models")
        let models2URL = session2URL.appendingPathComponent("Models")
        
        let modelURLs = [
            models1URL.appendingPathComponent("model1.usdz"),
            models1URL.appendingPathComponent("model2.usdz"),
            models2URL.appendingPathComponent("model3.usdz")
        ]
        
        // Setup URL retrieval
        setupURL(for: .documentDirectory, returning: documentsURL)
        
        // Setup directory listing
        contentsOfDirectoryStub = { url, keys, mask in
            switch url {
            case scansFolderURL:
                return [session1URL, session2URL]
            case models1URL:
                return [modelURLs[0], modelURLs[1]]
            case models2URL:
                return [modelURLs[2]]
            default:
                return []
            }
        }
        
        // Setup file existence
        fileExistsStub = { path, isDirectory in
            let paths = [models1URL.path, models2URL.path]
            if paths.contains(path) {
                isDirectory?.pointee = true
                return true
            }
            return false
        }
    }
}

