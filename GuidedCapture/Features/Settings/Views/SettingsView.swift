//
//  SettingsView.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 22.06.2024.
//

import SwiftUI
import SwiftData

/// Account settings screen with profile, notifications, and theme controls.
/// All state and persistence is managed by `SettingsViewModel`.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SettingsViewModel()
    @Query var users: [User]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeController: ThemeController

    var body: some View {
        NavigationStack {
            ZStack {
                OrtioDesignSystem.shellGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 22) {
                        SettingsHeader {
                            dismiss()
                        }

                        NavigationLink(destination: EditProfileView(viewModel: viewModel)) {
                            SettingsProfileCard(
                                title: viewModel.name,
                                subtitle: viewModel.user.username,
                                profileImage: viewModel.user.profileUIImage
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit profile")

                        SettingsCard(title: "Notifications") {
                            settingsRow(
                                icon: "bell",
                                title: "Push Notifications",
                                toggle: $viewModel.notificationsEnabled
                            )

                            settingsRow(
                                icon: "speaker.wave.2",
                                title: "Sound Effects",
                                toggle: $viewModel.soundEffectsEnabled
                            )

                            settingsRow(
                                icon: "envelope",
                                title: "Email Updates",
                                toggle: $viewModel.receiveEmailsEnabled,
                                isLast: true
                            )
                        }

                        SettingsCard(title: "Appearance") {
                            ThemePicker(selectedTheme: Binding(
                                get: { themeController.selectedTheme },
                                set: { newTheme in
                                    themeController.apply(theme: newTheme)
                                    viewModel.saveTheme(newTheme, context: modelContext)
                                }
                            ))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 48)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            viewModel.loadUser(from: users, context: modelContext)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func settingsRow(
        icon: String,
        title: String,
        toggle: Binding<Bool>,
        isLast: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.primary)
                    .frame(width: 20)

                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                Toggle("", isOn: toggle)
                    .labelsHidden()
                    .tint(OrtioDesignSystem.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isButton)

            if !isLast {
                Divider()
                    .padding(.leading, 48)
            }
        }
    }
}

// MARK: - ThemePicker

/// Vertical list of theme options (light, dark, system) with checkmark selection.
struct ThemePicker: View {
    @Binding var selectedTheme: Theme

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Theme.allCases, id: \.self) { theme in
                Button {
                    selectedTheme = theme
                } label: {
                    HStack {
                        Image(systemName: iconForTheme(theme))
                            .foregroundColor(.primary)
                            .frame(width: 20)

                        Text(theme.description)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Spacer()

                        if selectedTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundColor(OrtioDesignSystem.accent)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Select \(theme.description) theme")
            }
        }
    }

    private func iconForTheme(_ theme: Theme) -> String {
        switch theme {
        case .light: "sun.max"
        case .dark: "moon"
        case .system: "gear"
        }
    }
}

private struct SettingsHeader: View {
    let onClose: () -> Void

    var body: some View {
        HStack {
            Spacer()

            Text("Settings")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.headline.weight(.semibold))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(OrtioDesignSystem.elevatedSurface))
                    .overlay(Circle().stroke(OrtioDesignSystem.subtleBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .accessibilityLabel("Close settings")
        }
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(OrtioDesignSystem.mutedText)
                .textCase(.uppercase)
                .tracking(0.6)

            VStack(spacing: 0) {
                content
            }
            .ortioCardStyle()
        }
    }
}

private struct SettingsProfileCard: View {
    let title: String
    let subtitle: String
    let profileImage: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            if let profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 62, height: 62)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(OrtioDesignSystem.accentSoft)
                    .frame(width: 62, height: 62)
                    .overlay {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title)
                            .foregroundStyle(OrtioDesignSystem.accent)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle.isEmpty ? "Edit profile" : "@\(subtitle)")
                    .font(.subheadline)
                    .foregroundStyle(OrtioDesignSystem.mutedText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .ortioCardStyle()
    }
}
