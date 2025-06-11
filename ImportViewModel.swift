//
//  ImportViewModel.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 07.05.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftData
import SwiftUI
import Foundation

/// View model that manages importing model files into the app's document
/// directory.
class ImportViewModel: ObservableObject {
    /// The file manager used to interact with the file system. Can be injected
    /// for testing.
    private let fileManager: FileManagerProtocol

    /// Creates a new instance using the given ``FileManagerProtocol``.
    init(fileManager: FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }

    /// Generates a unique folder name from the specified date.
    /// - Parameter date: Optional date used as the base of the folder name.
    /// - Returns: A string suitable for use as a folder name.
    static func createUniqueFolderName(from date: Date?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = dateFormatter.string(from: date ?? Date())
        return "Model_\(dateString)"
    }
    
    /// Generates a unique file name for a file being imported.
    /// - Parameter originalURL: The original file URL.
    /// - Returns: A new unique file name.
    private func createUniqueFileName(originalURL: URL) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let timeStamp = dateFormatter.string(from: Date())
        let randomSequence = UUID().uuidString.prefix(8)
        let fileExtension = originalURL.pathExtension
        return "\(timeStamp)_\(randomSequence).\(fileExtension)"
    }
    
    /// Creates a new directory to store a scan session.
    /// - Returns: The created directory URL or `nil` on failure.
    internal func createNewScanDirectory() -> URL? {
        guard let capturesFolder = rootScansFolder() else {
            print("Can't get user document dir!")
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: Date())
        let newCaptureDir = capturesFolder.appendingPathComponent(timestamp, isDirectory: true)
        
        print("Creating capture path: \(newCaptureDir)")
        let capturePath = newCaptureDir.path
        do {
            try fileManager.createDirectory(atPath: capturePath, withIntermediateDirectories: true, attributes: nil)
            var url = URL(fileURLWithPath: capturePath)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
        } catch {
            print("Failed to create capture path: \(capturePath) with error: \(error)")
            return nil
        }
        
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: capturePath, isDirectory: &isDir)
        guard exists && isDir.boolValue else {
            return nil
        }
        
        return newCaptureDir
    }
    
    /// The root folder used to store scans.
    /// - Returns: The URL of the scans folder or `nil` if it can't be resolved.
    private func rootScansFolder() -> URL? {
        guard let documentsFolder = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            return nil
        }
        return documentsFolder.appendingPathComponent("Scans/", isDirectory: true)
    }
}
