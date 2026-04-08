//
//  Models.swift
//  Ortio
//
//  Created by Matyas Vascak on 24.12.2023.
//

import Foundation
import SwiftData

/// SwiftData model for an imported 3D file. Stored under `Documents/Imports/`.
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
