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
                    .tint(.black)

                Button("Import File", action: onImport)
                    .buttonStyle(.bordered)
                    .tint(.primary)
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
                ZStack {
                    Circle()
                        .fill(isSelected ? OrtioDesignSystem.accentSoft : OrtioDesignSystem.elevatedSurface)
                        .frame(width: 64, height: 64)
                        .overlay(Circle().stroke(OrtioDesignSystem.subtleBorder, lineWidth: 1))
                        .ortioQuickActionGlassCircle(isSelected: isSelected)

                    Image(systemName: systemName)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.primary)
                }

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

private extension View {
    @ViewBuilder
    func ortioQuickActionGlassCircle(isSelected: Bool) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(
                .regular
                    .tint(isSelected ? OrtioDesignSystem.accentSoft : OrtioDesignSystem.elevatedSurface.opacity(0.72))
                    .interactive(),
                in: Circle()
            )
        } else {
            self
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
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .background(Capsule(style: .continuous).fill(Color.black.opacity(0.88)))
                .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 14)
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
                        .foregroundStyle(.primary)
                }

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .ortioCardStyle()
        }
        .buttonStyle(.plain)
    }
}
