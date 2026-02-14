//
//  Theme.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 22.06.2024.
//

import SwiftUI

/// App appearance theme, stored in the `User` SwiftData model.
enum Theme: String, CaseIterable, Identifiable, Codable {
    case light
    case dark
    case system

    var id: String { self.rawValue }

    var description: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .system: "System"
        }
    }

    /// Maps to SwiftUI's `ColorScheme`. Returns `nil` for `.system` to follow device setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}
