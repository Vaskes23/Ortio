//
//  SettingsView.swift
//  Ortio
//
//  Created by Matyas Vascak on 22.06.2024.
//

import AuthenticationServices
import os
import SwiftData
import SwiftUI

/// Account settings screen with profile, notifications, and theme controls.
/// All state and persistence is managed by `SettingsViewModel`.
struct SettingsView: View {
    private static let logger = Logger(
        subsystem: OrtioApp.subsystem,
        category: "AppleSignIn"
    )

    /// Service boundary for Google's OAuth flow and compact profile extraction.
    private let googleSignInService = GoogleSignInService()

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeController: ThemeController
    @Query var users: [User]

    @State private var viewModel = SettingsViewModel()
    @State private var showingSignInRequired = false
    /// Prevents duplicate Google authorization sheets while the async sign-in flow is active.
    @State private var isGoogleSignInInProgress = false

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

                        profileEntry

                        if !viewModel.isAuthenticated {
                            SettingsCard(title: "Account Sync") {
                                AccountSyncPrompt(
                                    isGoogleSignInInProgress: isGoogleSignInInProgress,
                                    onGoogleSignIn: handleGoogleSignIn,
                                    onAppleSignIn: handleAppleSignIn
                                )
                            }
                        }

                        if viewModel.isAuthenticated {
                            signedInControls
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
        .alert("Sign in required", isPresented: $showingSignInRequired) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("To edit user information, sign in or sign up with Google or Apple ID.")
        }
    }

    @ViewBuilder
    private var profileEntry: some View {
        if viewModel.isAuthenticated {
            NavigationLink(destination: EditProfileView(viewModel: viewModel)) {
                SettingsProfileCard(
                    title: viewModel.name,
                    subtitle: viewModel.user.username,
                    profileImage: viewModel.user.profileUIImage
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit profile")
        } else {
            Button {
                showingSignInRequired = true
            } label: {
                SettingsProfileCard(
                    title: viewModel.name,
                    subtitle: viewModel.user.username,
                    profileImage: viewModel.user.profileUIImage
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Locked profile")
        }
    }

    private var signedInControls: some View {
        Group {
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
    }

    private func handleGoogleSignIn() {
        Task { await signInWithGoogle() }
    }

    /// Runs Google's OAuth flow, then persists only the compact account profile returned by the service.
    @MainActor
    private func signInWithGoogle() async {
        guard !isGoogleSignInInProgress else { return }

        isGoogleSignInInProgress = true
        defer { isGoogleSignInInProgress = false }

        do {
            let profile = try await googleSignInService.signIn()
            viewModel.completeGoogleSignIn(profile, context: modelContext)
        } catch {
            viewModel.errorMessage = "Google sign-in failed: \(error.localizedDescription)"
        }
    }

    /// Handles Apple's authorization callback while ignoring explicit user cancellation.
    private func handleAppleSignIn(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                viewModel.errorMessage = "Apple did not return a valid sign-in credential."
                return
            }

            viewModel.completeAppleSignIn(
                identifier: credential.user,
                email: credential.email,
                fullName: credential.fullName,
                context: modelContext
            )
        case .failure(let error):
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                return
            }

            Self.logAppleSignInFailure(error)
            viewModel.errorMessage = "Apple sign-in failed: \(error.localizedDescription)"
        }
    }

    /// Logs authorization diagnostics without persisting credentials or profile identifiers.
    private static func logAppleSignInFailure(_ error: any Error) {
        let nsError = error as NSError
        logger.error(
            """
            Apple sign-in failed. domain=\(nsError.domain, privacy: .public), \
            code=\(nsError.code, privacy: .public), \
            userInfo=\(sanitizedUserInfoDescription(nsError.userInfo), privacy: .public)
            """
        )
    }

    /// Produces a deterministic log-safe summary of Apple authorization error metadata.
    private static func sanitizedUserInfoDescription(_ userInfo: [String: Any]) -> String {
        guard !userInfo.isEmpty else { return "[:]" }

        let entries = userInfo
            .sorted { $0.key < $1.key }
            .map { key, value in
                "\(key): \(sanitizedUserInfoValue(value))"
            }

        return "[\(entries.joined(separator: ", "))]"
    }

    /// Redacts nested errors and string payloads before they are written to unified logging.
    private static func sanitizedUserInfoValue(_ value: Any) -> String {
        if let error = value as? NSError {
            return "NSError(domain: \(error.domain), code: \(error.code), userInfo: \(sanitizedUserInfoDescription(error.userInfo)))"
        }

        if let string = value as? String {
            return redactedPotentiallySensitiveContent(string)
        }

        return "<\(type(of: value))>"
    }

    /// Removes emails and long token-like identifiers from diagnostic strings.
    private static func redactedPotentiallySensitiveContent(_ value: String) -> String {
        let emailPattern = #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#
        let withoutEmails = value.replacingOccurrences(
            of: emailPattern,
            with: "<redacted-email>",
            options: [.regularExpression, .caseInsensitive]
        )

        let tokenPattern = #"[A-Za-z0-9_-]{24,}"#
        return withoutEmails.replacingOccurrences(
            of: tokenPattern,
            with: "<redacted-identifier>",
            options: .regularExpression
        )
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
                    .foregroundColor(OrtioDesignSystem.Palette.primaryText)
                    .frame(width: 20)

                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(OrtioDesignSystem.Palette.primaryText)

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
                            .foregroundColor(OrtioDesignSystem.Palette.primaryText)
                            .frame(width: 20)

                        Text(theme.description)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(OrtioDesignSystem.Palette.primaryText)

                        Spacer()

                        if selectedTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundColor(OrtioDesignSystem.accent)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(OrtioDesignSystem.Palette.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
                .foregroundStyle(OrtioDesignSystem.Palette.primaryText)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.headline.weight(.semibold))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(OrtioDesignSystem.elevatedSurface))
                    .overlay(Circle().stroke(OrtioDesignSystem.subtleBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .foregroundStyle(OrtioDesignSystem.Palette.primaryText)
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

/// Locked account prompt that offers Google as the working provider and keeps Apple visible.
private struct AccountSyncPrompt: View {
    let isGoogleSignInInProgress: Bool
    let onGoogleSignIn: () -> Void
    let onAppleSignIn: (Result<ASAuthorization, any Error>) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sign in or sign up")
                    .font(.headline)
                    .foregroundStyle(OrtioDesignSystem.Palette.primaryText)

                Text("Use Google or Apple ID to edit your profile and account settings.")
                    .font(.subheadline)
                    .foregroundStyle(OrtioDesignSystem.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: onGoogleSignIn) {
                HStack(spacing: 12) {
                    if isGoogleSignInInProgress {
                        ProgressView()
                            .tint(OrtioDesignSystem.Palette.primaryText)
                    } else {
                        Text("G")
                            .font(.headline.weight(.semibold))
                            .frame(width: 20)
                    }

                    Text(isGoogleSignInInProgress ? "Signing in..." : "Continue with Google")
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Spacer(minLength: 0)
                }
                .foregroundStyle(OrtioDesignSystem.Palette.primaryText)
                .padding(.horizontal, 22)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(OrtioDesignSystem.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(OrtioDesignSystem.subtleBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isGoogleSignInInProgress)
            .accessibilityLabel("Continue with Google")

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                onAppleSignIn(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityLabel("Sign in with Apple ID")
        }
        .padding(16)
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
                    .foregroundStyle(OrtioDesignSystem.Palette.primaryText)

                Text(subtitle.isEmpty ? "Edit profile" : "@\(subtitle)")
                    .font(.subheadline)
                    .foregroundStyle(OrtioDesignSystem.mutedText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(OrtioDesignSystem.Palette.secondaryText)
        }
        .padding(18)
        .ortioCardStyle()
    }
}
