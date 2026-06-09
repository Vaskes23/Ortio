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
            VStack(spacing: 7) {
                Text(title)
                    .font(.custom("Helvetica-Bold", size: 12))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : OrtioDesignSystem.secondary)
            .frame(width: 62, height: 68)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .ortioQuickActionGlassSurface(isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    @ViewBuilder
    func ortioQuickActionGlassSurface(isSelected: Bool) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(
                .regular
                    .tint(isSelected ? OrtioDesignSystem.secondary : OrtioDesignSystem.secondary.opacity(0.12))
                    .interactive(),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isSelected ? OrtioDesignSystem.secondary : OrtioDesignSystem.elevatedSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(OrtioDesignSystem.secondary.opacity(isSelected ? 0.34 : 0.14), lineWidth: 1)
                )
                .shadow(color: OrtioDesignSystem.shadow, radius: 14, x: 0, y: 8)
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
