//
//  HomeDashboardView+QuickActions.swift
//  Ortio
//

import SwiftUI

// MARK: - EmptyLibraryCard

struct EmptyLibraryCard: View {
    let onScan: () -> Void
    let onImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nothing here yet")
                .font(.title3.weight(.semibold))

            HStack(spacing: 12) {
                Button("Start Scan", action: onScan)
                    .buttonStyle(.borderedProminent)
                    .tint(OrtioDesignSystem.Palette.primaryAccent)

                Button("Import File", action: onImport)
                    .buttonStyle(.bordered)
                    .tint(OrtioDesignSystem.Palette.primaryText)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ortioCardStyle()
    }
}

// MARK: - HomeQuickActionButton

struct HomeQuickActionButton: View {
    let title: String
    let systemName: String
    let rotationDegrees: Double
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                QuickActionIconGlassSurface(
                    systemName: systemName,
                    rotationDegrees: rotationDegrees,
                    isSelected: isSelected
                )

                Text(title)
                    .font(.custom("Helvetica-Bold", size: 11))
                    .foregroundStyle(OrtioDesignSystem.mutedText.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(width: 74)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct QuickActionIconGlassSurface: View {
    let systemName: String
    let rotationDegrees: Double
    let isSelected: Bool

    @ViewBuilder
    var body: some View {
        if #available(iOS 26, *) {
            iconContent
                .frame(width: 58, height: 58)
                .background {
                    Circle()
                        .fill(isSelected ? OrtioDesignSystem.Palette.selectedGlassTint : OrtioDesignSystem.Palette.glassTransitionFill)
                }
                .overlay(Circle().stroke(OrtioDesignSystem.subtleBorder, lineWidth: 1))
                .glassEffect(
                    .regular
                        .tint(isSelected ? OrtioDesignSystem.Palette.selectedGlassEffectTint : OrtioDesignSystem.Palette.glassTint)
                        .interactive(),
                    in: Circle()
                )
        } else {
            iconContent
                .frame(width: 58, height: 58)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .background(
                            Circle()
                                .fill(isSelected ? OrtioDesignSystem.Palette.selectedGlassTint : OrtioDesignSystem.Palette.mutedGlassFill)
                        )
                )
                .overlay(Circle().stroke(OrtioDesignSystem.subtleBorder, lineWidth: 1))
                .shadow(color: OrtioDesignSystem.shadow.opacity(0.55), radius: 12, x: 0, y: 7)
        }
    }

    @ViewBuilder
    private var iconContent: some View {
        Image(systemName: systemName)
            .font(.system(size: 27, weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(OrtioDesignSystem.Palette.primaryText)
            .rotationEffect(.degrees(rotationDegrees))
    }
}
// MARK: - ScanPillButton

struct ScanPillButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label("Scan", systemImage: "camera")
                .font(.headline.weight(.semibold))
                .foregroundStyle(OrtioDesignSystem.Palette.lightText)
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .background(Capsule(style: .continuous).fill(OrtioDesignSystem.Palette.primaryAccent))
                .shadow(color: OrtioDesignSystem.Palette.strongShadow, radius: 24, x: 0, y: 14)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start new scan")
    }
}

// MARK: - HomeShareSheet

struct HomeShareSheet: View {
    var body: some View {
        NavigationStack {
            OrtioDesignSystem.shellGradient
                .ignoresSafeArea()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}
