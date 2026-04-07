//
//  OrtioDesignSystem.swift
//  GuidedCapture
//
//  Created by OpenAI on 07.04.2026.
//

import SwiftUI

enum OrtioDesignSystem {
    static let shellGradient = LinearGradient(
        colors: [
            Color(red: 0.99, green: 0.98, blue: 0.97),
            Color.white,
            Color(red: 0.96, green: 0.96, blue: 0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let surface = Color.white.opacity(0.82)
    static let elevatedSurface = Color.white.opacity(0.94)
    static let subtleBorder = Color.black.opacity(0.05)
    static let accent = Color(red: 0.94, green: 0.63, blue: 0.55)
    static let accentSoft = Color(red: 0.99, green: 0.92, blue: 0.89)
    static let shadow = Color.black.opacity(0.08)
    static let mutedText = Color.secondary

    enum Radius {
        static let large: CGFloat = 30
        static let medium: CGFloat = 24
        static let small: CGFloat = 18
    }
}

struct OrtioCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: OrtioDesignSystem.Radius.medium, style: .continuous)
                    .fill(OrtioDesignSystem.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OrtioDesignSystem.Radius.medium, style: .continuous)
                    .stroke(OrtioDesignSystem.subtleBorder, lineWidth: 1)
            )
            .shadow(color: OrtioDesignSystem.shadow, radius: 18, x: 0, y: 10)
    }
}

extension View {
    func ortioCardStyle() -> some View {
        modifier(OrtioCardModifier())
    }
}
