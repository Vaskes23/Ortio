//
//  ModelsMocks.swift
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

    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL] {
        return try contentsOfDirectoryStub?(url, keys, mask) ?? []
    }
    
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        return fileExistsStub?(path, isDirectory) ?? false
    }
    
    func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask, appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL {
        return try urlStub?(directory, domain, url, shouldCreate) ?? URL(fileURLWithPath: "")
    }
}

