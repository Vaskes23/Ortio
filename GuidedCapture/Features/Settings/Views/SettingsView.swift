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
    @State private var viewModel = SettingsViewModel()
    @Query var users: [User]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appModel: AppDataModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Profile Section
                    VStack(spacing: 16) {
                        sectionHeader("Profile")

                        VStack(spacing: 0) {
                            NavigationLink(destination: EditProfileView(name: $viewModel.name)) {
                                ProfileItemView(
                                    title: viewModel.name,
                                    subtitle: "View Profile",
                                    profileImage: viewModel.user.profileUIImage
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("Edit profile")
                        }
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Notifications Section
                    VStack(spacing: 16) {
                        sectionHeader("Notifications")

                        VStack(spacing: 0) {
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
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Appearance Section
                    VStack(spacing: 16) {
                        sectionHeader("Appearance")

                        VStack(spacing: 0) {
                            ThemePicker(selectedTheme: $appModel.selectedTheme.onChange {
                                appModel.saveTheme(user: viewModel.user, context: modelContext)
                            })
                        }
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
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

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, 4)
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

// MARK: - Binding Extension

extension Binding {
    /// Returns a new binding that calls `handler` whenever the value is set.
    func onChange(_ handler: @escaping () -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler()
            }
        )
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
                                .foregroundColor(.blue)
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

// MARK: - ProfileItemView

struct ProfileItemView: View {
    var title: String
    var subtitle: String
    var profileImage: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}
