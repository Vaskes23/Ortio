//
//  FileManagerProtocol.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import Combine

/// A protocol that abstracts ``FileManager`` APIs to make them testable.
protocol FileManagerProtocol {
    /// Returns the contents of the directory at the specified URL.
    func contentsOfDirectory(at url: URL,
                             includingPropertiesForKeys keys: [URLResourceKey]?,
                             options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL]

    /// Checks for the existence of a file at the specified path.
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool

    /// Returns a URL for the specified directory.
    func url(for directory: FileManager.SearchPathDirectory,
             in domain: FileManager.SearchPathDomainMask,
             appropriateFor url: URL?,
             create shouldCreate: Bool) throws -> URL

    /// Creates a directory at the specified path.
    func createDirectory(atPath path: String,
                         withIntermediateDirectories: Bool,
                         attributes: [FileAttributeKey: Any]?) throws

    /// Retrieves attributes of the file at the given path.
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]

    /// Copies an item from the source URL to the destination URL.
    func copyItem(at srcURL: URL, to dstURL: URL) throws
}

extension FileManager: FileManagerProtocol {}
