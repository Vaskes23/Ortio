//
//  OrtioDesignSystem.swift
//  Ortio
//
//  Created by OpenAI on 07.04.2026.
//

import SwiftUI
import UIKit

/// Shared visual tokens and reusable surface helpers for Ortio screens.
///
/// Feature views should prefer these values over one-off colors, radii, shadows,
/// or glass fallbacks so the app remains visually consistent.
enum OrtioDesignSystem {
    enum Palette {
        static let background = Color(hex: 0xE3E4E4)
        static let surface = Color(hex: 0xF4F4F5)
        static let darkText = Color(hex: 0x111111)
        static let primaryAccent = Color(hex: 0x002FA7)
        static let secondary = Color(hex: 0x8E8E8E)
        static let highlight = Color(hex: 0x00A36C)

        static let clear = Color.clear
        static let lightText = surface
        static let primaryText = darkText
        static let secondaryText = secondary
        static let tertiaryText = secondary.opacity(0.58)
        static let border = darkText.opacity(0.10)
        static let subtleBorder = darkText.opacity(0.05)
        static let shadow = darkText.opacity(0.10)
        static let strongShadow = darkText.opacity(0.18)
        static let glassTransitionFill = darkText.opacity(0.035)
        static let glassTint = surface.opacity(0.08)
        static let selectedGlassTint = primaryAccent.opacity(0.28)
        static let selectedGlassEffectTint = primaryAccent.opacity(0.45)
        static let mutedGlassFill = surface.opacity(0.32)
        static let overlayScrim = darkText.opacity(0.50)
        static let destructive = Color(uiColor: .systemRed)
        static let favorite = Color(uiColor: .systemYellow)
    }

    static var shellGradient: Color {
        appBackground
    }

    static var appBackground: Color {
        Palette.background
    }

    static var surface: Color {
        Palette.surface.opacity(0.82)
    }

    static var elevatedSurface: Color {
        Palette.surface.opacity(0.94)
    }

    static var subtleBorder: Color {
        Palette.subtleBorder
    }

    static let accent = Palette.primaryAccent

    static var accentSoft: Color {
        Palette.primaryAccent.opacity(0.12)
    }

    static var shadow: Color {
        Palette.shadow
    }

    static var mutedText: Color {
        Palette.secondaryText
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

private extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

/// Standard elevated card treatment for repeated content surfaces.
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
