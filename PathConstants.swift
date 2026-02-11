//
//  PathConstants.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 22.06.2024.
//

import Foundation

/// Folder names used under `Documents/` for file storage.
/// These are path components, not full paths — append to a documents URL via `appendingPathComponent`.
enum PathConstants {
    static let scans = "Scans"
    static let imports = "Imports"
    static let images = "Images"
    static let snapshots = "Snapshots"
    static let models = "Models"
}
