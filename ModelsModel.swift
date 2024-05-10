//
//  ModelsModel.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 07.05.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation

struct ModelsModel{

    struct IdentifiableCaptureURL: Identifiable {
        let id = UUID()
        let url: URL
    }
}
