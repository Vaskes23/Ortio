//
//  ModelsModel.swift
//  Ortio
//
//  Created by Matyas Vascak on 07.05.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation

struct ModelsModel {

    struct IdentifiableCaptureURL: Identifiable {
        let url: URL
        var id: String { url.standardizedFileURL.path }
    }
}
