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
        static let background = Color(light: 0xE3E4E4, dark: 0x050A18)
        static let surface = Color(light: 0xF4F4F5, dark: 0x111B33)
        static let darkText = Color(hex: 0x111111)
        static let primaryAccent = Color(hex: 0x002FA7)
        static let secondary = Color(hex: 0x8E8E8E)
        static let highlight = Color(hex: 0x00A36C)

        static let clear = Color.clear
        static let lightText = Color(light: 0xF4F4F5, dark: 0xF4F4F5)
        static let primaryText = Color(light: 0x111111, dark: 0xF4F4F5)
        static let secondaryText = Color(light: 0x8E8E8E, dark: 0xB9BBC2)
        static let tertiaryText = Color(light: 0x8E8E8E, dark: 0x787D8C, lightAlpha: 0.58, darkAlpha: 0.72)
        static let border = Color(light: 0x111111, dark: 0xF4F4F5, lightAlpha: 0.10, darkAlpha: 0.16)
        static let subtleBorder = Color(light: 0x111111, dark: 0xF4F4F5, lightAlpha: 0.05, darkAlpha: 0.11)
        static let shadow = Color(light: 0x111111, dark: 0x000000, lightAlpha: 0.10, darkAlpha: 0.42)
        static let strongShadow = Color(light: 0x111111, dark: 0x000000, lightAlpha: 0.18, darkAlpha: 0.58)
        static let glassTransitionFill = Color(light: 0x111111, dark: 0xF4F4F5, lightAlpha: 0.035, darkAlpha: 0.08)
        static let glassTint = Color(light: 0xF4F4F5, dark: 0x111B33, lightAlpha: 0.08, darkAlpha: 0.70)
        static let selectedGlassTint = Color(light: 0x002FA7, dark: 0x002FA7, lightAlpha: 0.14, darkAlpha: 0.36)
        static let selectedGlassEffectTint = Color(light: 0x002FA7, dark: 0x002FA7, lightAlpha: 0.22, darkAlpha: 0.50)
        static let mutedGlassFill = Color(light: 0xF4F4F5, dark: 0x111B33, lightAlpha: 0.32, darkAlpha: 0.88)
        static let overlayScrim = Color(light: 0x111111, dark: 0x000000, lightAlpha: 0.50, darkAlpha: 0.72)
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
    init(light: UInt, dark: UInt, lightAlpha: Double = 1, darkAlpha: Double = 1) {
        self.init(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(hex: dark, alpha: darkAlpha)
                    : UIColor(hex: light, alpha: lightAlpha)
            }
        )
    }

    init(hex: UInt, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

private extension UIColor {
    convenience init(hex: UInt, alpha: Double = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
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
            self.glassEffect(
                .regular
                    .tint(OrtioDesignSystem.Palette.glassTint)
                    .interactive(),
                in: Capsule(style: .continuous)
            )
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
            self.glassEffect(
                .regular
                    .tint(OrtioDesignSystem.Palette.glassTint)
                    .interactive(),
                in: Circle()
            )
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
