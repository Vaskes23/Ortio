//
//  FileManagerProtocol.swift
//  Ortio
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import Combine

protocol FileManagerProtocol {
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL]
    
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool
    
    func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask, appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL
    
    func createDirectory(atPath path: String, withIntermediateDirectories: Bool, attributes: [FileAttributeKey: Any]?) throws
    
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
    
    func copyItem(at srcURL: URL, to dstURL: URL) throws
}

extension FileManager: FileManagerProtocol {}
