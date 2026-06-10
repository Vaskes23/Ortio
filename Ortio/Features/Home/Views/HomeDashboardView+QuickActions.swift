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
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                QuickActionIconGlassSurface(systemName: systemName, isSelected: isSelected)

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
    let isSelected: Bool

    @ViewBuilder
    var body: some View {
        if #available(iOS 26, *) {
            Image(systemName: systemName)
                .font(.system(size: 27, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(OrtioDesignSystem.Palette.primaryText)
                .frame(width: 64, height: 64)
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
            Image(systemName: systemName)
                .font(.system(size: 27, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(OrtioDesignSystem.Palette.primaryText)
                .frame(width: 64, height: 64)
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

// MARK: - HomeToolsSheet

struct HomeToolsSheet: View {
    let onNewScan: () -> Void
    let onImport: () -> Void
    let onHelp: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick tools")
                        .font(.largeTitle.weight(.bold))

                    ToolActionCard(
                        title: "New Scan",
                        systemName: "camera.viewfinder",
                        action: onNewScan
                    )

                    ToolActionCard(
                        title: "Import File",
                        systemName: "square.and.arrow.down",
                        action: onImport
                    )

                    ToolActionCard(
                        title: "Preview Help",
                        systemName: "questionmark.circle",
                        action: onHelp
                    )
                }
                .padding(20)
            }
            .background(OrtioDesignSystem.shellGradient.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - ToolActionCard

struct ToolActionCard: View {
    let title: String
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(OrtioDesignSystem.accentSoft)
                        .frame(width: 58, height: 58)

                    Image(systemName: systemName)
                        .font(.title3)
                        .foregroundStyle(OrtioDesignSystem.Palette.primaryText)
                }

                Text(title)
                    .font(.headline)
                    .foregroundStyle(OrtioDesignSystem.Palette.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(OrtioDesignSystem.Palette.secondaryText)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .ortioCardStyle()
        }
        .buttonStyle(.plain)
    }
}
