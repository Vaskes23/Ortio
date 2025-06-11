//
//  ModelsModel.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 07.05.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation

/// Model used to represent captured model URLs.
struct ModelsModel {

    /// URL wrapper for capture results.
    struct IdentifiableCaptureURL: Identifiable {
        /// Unique identifier for the capture.
        let id = UUID()
        /// Location of the model on disk.
        let url: URL
    }
}
