//
//  ImportModel.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 07.05.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation

/// A model used for file imports.
struct ImportModel {

    /// A URL wrapper that conforms to ``Identifiable``.
    struct IdentifiableURL: Identifiable {
        /// Unique identifier for the URL.
        let id: UUID = UUID()
        /// The underlying file URL.
        let url: URL
    }
}

