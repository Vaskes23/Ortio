//
//  OrtioDesignSystem.swift
//  Ortio
//
//  Created by OpenAI on 07.04.2026.
//

import SwiftUI
import UIKit

enum OrtioDesignSystem {
    static var shellGradient: LinearGradient {
        LinearGradient(
            colors: [
                dynamicColor(
                    light: UIColor(red: 0.99, green: 0.98, blue: 0.97, alpha: 1),
                    dark: UIColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
                ),
                dynamicColor(
                    light: .white,
                    dark: UIColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1)
                ),
                dynamicColor(
                    light: UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1),
                    dark: UIColor(red: 0.11, green: 0.12, blue: 0.16, alpha: 1)
                )
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var surface: Color {
        dynamicColor(
            light: UIColor(white: 1, alpha: 0.82),
            dark: UIColor(red: 0.15, green: 0.16, blue: 0.20, alpha: 0.84)
        )
    }

    static var elevatedSurface: Color {
        dynamicColor(
            light: UIColor(white: 1, alpha: 0.94),
            dark: UIColor(red: 0.18, green: 0.19, blue: 0.24, alpha: 0.94)
        )
    }

    static var subtleBorder: Color {
        dynamicColor(
            light: UIColor.black.withAlphaComponent(0.05),
            dark: UIColor.white.withAlphaComponent(0.10)
        )
    }

    static let accent = Color(red: 0.94, green: 0.63, blue: 0.55)
    static let secondary = Color(red: 0, green: 47.0 / 255.0, blue: 167.0 / 255.0)

    static var accentSoft: Color {
        dynamicColor(
            light: UIColor(red: 0.99, green: 0.92, blue: 0.89, alpha: 1),
            dark: UIColor(red: 0.30, green: 0.20, blue: 0.18, alpha: 0.86)
        )
    }

    static var shadow: Color {
        dynamicColor(
            light: UIColor.black.withAlphaComponent(0.08),
            dark: UIColor.black.withAlphaComponent(0.36)
        )
    }

    static var mutedText: Color {
        Color(uiColor: .secondaryLabel)
    }

    enum Radius {
        static let large: CGFloat = 30
        static let medium: CGFloat = 24
        static let small: CGFloat = 18
    }

    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        )
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

    @ViewBuilder
    func ortioHeaderGlassCapsule() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular.interactive(), in: Capsule(style: .continuous))
        } else {
            self
                .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(OrtioDesignSystem.subtleBorder, lineWidth: 1)
                )
                .shadow(color: OrtioDesignSystem.shadow, radius: 16, x: 0, y: 10)
        }
    }

    @ViewBuilder
    func ortioHeaderGlassCircle() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular.interactive(), in: Circle())
        } else {
            self
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(OrtioDesignSystem.subtleBorder, lineWidth: 1)
                )
                .shadow(color: OrtioDesignSystem.shadow, radius: 16, x: 0, y: 10)
        }
    }
}
