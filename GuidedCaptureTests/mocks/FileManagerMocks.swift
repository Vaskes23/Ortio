//
//  FileManagerMocks.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
@testable import GuidedCapture

import Foundation
import Combine

class MockFileManager: FileManagerProtocol {
    var contentsOfDirectoryStub: ((URL, [URLResourceKey]?, FileManager.DirectoryEnumerationOptions) throws -> [URL])?
    var fileExistsStub: ((String, UnsafeMutablePointer<ObjCBool>?) -> Bool)?
    var urlStub: ((FileManager.SearchPathDirectory, FileManager.SearchPathDomainMask, URL?, Bool) throws -> URL)?
    var createDirectoryStub: ((String, Bool, [FileAttributeKey: Any]?) throws -> Void)?
    var attributesOfItemStub: ((String) throws -> [FileAttributeKey: Any])?
    var copyItemStub: ((URL, URL) throws -> Void)?
    
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL] {
        return try contentsOfDirectoryStub?(url, keys, mask) ?? []
    }

    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        return fileExistsStub?(path, isDirectory) ?? false
    }

    func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask, appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL {
        return try urlStub?(directory, domain, url, shouldCreate) ?? URL(fileURLWithPath: "")
    }

    func createDirectory(atPath path: String, withIntermediateDirectories: Bool, attributes: [FileAttributeKey: Any]?) throws {
        try createDirectoryStub?(path, withIntermediateDirectories, attributes)
    }

    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        return try attributesOfItemStub?(path) ?? [:]
    }

    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        try copyItemStub?(srcURL, dstURL)
    }
}

