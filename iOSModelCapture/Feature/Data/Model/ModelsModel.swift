//
//  ModelsModel.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 07.05.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import SwiftData

@Model final class Models: Identifiable {
    @Attribute(.unique) var name: String
    var date: Date
    var imported: Bool
    var favorite: Bool
    var size: Double
    @Attribute(.unique) var model: URL
    
    init(name: String, date: Date, favorite: Bool, imported: Bool, size: Double, model: URL) {
        self.name = name
        self.date = date
        self.favorite = favorite
        self.imported = imported
        self.size = size
        self.model = model
    }
}

struct ModelsModel{

    struct IdentifiableCaptureURL: Identifiable {
        let id = UUID()
        let url: URL
    }
}