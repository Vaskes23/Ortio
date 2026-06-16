//
//  GoogleSignInService.swift
//  Ortio
//
//  Created by OpenAI on 16.06.2026.
//

import Foundation
import GoogleSignIn
import UIKit

/// Compact Google account profile returned after a successful sign-in.
///
/// Access and refresh tokens stay inside the Google Sign-In SDK. The settings
/// feature only persists the fields needed to unlock local account settings and
/// prefill the profile.
struct GoogleAccountProfile: Equatable {
    /// Normalized Google account email used as Ortio's compact local account identity.
    let email: String

    /// Optional display name from the Google profile, used to prefill the editable profile name.
    let fullName: String?

    /// Optional downloaded profile image bytes. The service bounds this payload before persistence.
    let avatarData: Data?
}

/// Errors surfaced by the Google Sign-In setup before or during OAuth.
enum GoogleSignInServiceError: LocalizedError, Equatable {
    /// The built app did not receive the iOS OAuth client ID from its Info.plist.
    case missingClientID

    /// The built app did not receive the reversed client ID URL scheme needed for OAuth redirects.
    case missingURLScheme

    /// SwiftUI could not provide a UIKit presenter for Google's authorization sheet.
    case missingPresenter

    /// Google completed authorization but did not return the email Ortio uses as its local account key.
    case missingProfileEmail

    /// User-facing recovery message for setup and authorization failures.
    var errorDescription: String? {
        switch self {
        case .missingClientID:
            "Google sign-in is missing GIDClientID. Add GOOGLE_SIGN_IN_CLIENT_ID to Configuration/Secrets.xcconfig."
        case .missingURLScheme:
            "Google sign-in is missing its reversed client ID URL scheme. Add GOOGLE_SIGN_IN_REVERSED_CLIENT_ID to Configuration/Secrets.xcconfig."
        case .missingPresenter:
            "Google sign-in could not find a presentation window."
        case .missingProfileEmail:
            "Google did not return an email address for this account."
        }
    }
}

/// Thin wrapper around the Google Sign-In SDK for the settings account flow.
@MainActor
protocol GoogleSignInServicing {
    /// Starts an interactive Google authorization flow from the current key window.
    ///
    /// The implementation must stay on the main actor because Google's SDK
    /// presents UIKit UI and reads the app's foreground scene.
    func signIn() async throws -> GoogleAccountProfile

    /// Restores a prior Google session when the SDK has valid tokens in Keychain.
    ///
    /// Implementations return `nil` for the normal "no prior auth" path so cold
    /// launches do not surface a user-facing error.
    func restorePreviousSignIn() async throws -> GoogleAccountProfile?
}

/// Production Google Sign-In implementation backed by `GIDSignIn`.
///
/// OAuth credentials are read from the built Info.plist and therefore come from
/// `Configuration/Secrets.xcconfig` at build time. Tokens remain managed by the
/// Google SDK and iOS Keychain; this service returns only profile data that the
/// settings feature is allowed to persist.
@MainActor
final class GoogleSignInService: GoogleSignInServicing {
    /// Starts Google's interactive sign-in UI and converts the resulting SDK user into a compact profile.
    func signIn() async throws -> GoogleAccountProfile {
        try configureFromBundle()

        guard let presenter = UIApplication.shared.ortioTopViewController() else {
            throw GoogleSignInServiceError.missingPresenter
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        return try await profile(from: result.user)
    }

    /// Attempts a silent session restore and suppresses the expected "not signed in" Keychain miss.
    func restorePreviousSignIn() async throws -> GoogleAccountProfile? {
        try configureFromBundle()

        do {
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            return try await profile(from: user)
        } catch {
            return nil
        }
    }

    /// Configures `GIDSignIn` from build-time Info.plist values.
    ///
    /// Empty build-setting placeholders such as `"$(GOOGLE_SIGN_IN_CLIENT_ID)"`
    /// are treated as missing so local setup errors are reported before Google
    /// opens a browser session.
    private func configureFromBundle() throws {
        let clientID = try requiredBundleValue(for: "GIDClientID", missingError: .missingClientID)
        _ = try requiredBundleValue(for: "GoogleSignInURLScheme", missingError: .missingURLScheme)
        let serverClientID = optionalBundleValue(for: "GIDServerClientID")

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: clientID,
            serverClientID: serverClientID
        )
    }

    /// Reads a required Info.plist value and maps absence to a specific setup error.
    private func requiredBundleValue(
        for key: String,
        missingError: GoogleSignInServiceError
    ) throws -> String {
        guard let value = optionalBundleValue(for: key) else {
            throw missingError
        }

        return value
    }

    /// Returns a non-empty Info.plist value after filtering unresolved build-setting placeholders.
    private func optionalBundleValue(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty, !trimmedValue.contains("$(") else {
            return nil
        }

        return trimmedValue
    }

    /// Extracts the durable profile fields Ortio stores after Google authorization succeeds.
    private func profile(from user: GIDGoogleUser) async throws -> GoogleAccountProfile {
        guard let email = normalizedValue(user.profile?.email) else {
            throw GoogleSignInServiceError.missingProfileEmail
        }

        let avatarURL = user.profile?.imageURL(withDimension: 160)
        let avatarData = await avatarData(from: avatarURL)

        return GoogleAccountProfile(
            email: email,
            fullName: normalizedValue(user.profile?.name),
            avatarData: avatarData
        )
    }

    /// Downloads a small avatar image and drops failures because profile images are optional.
    private func avatarData(from url: URL?) async -> Data? {
        guard let url else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode,
                  data.count <= 512_000 else {
                return nil
            }

            return data
        } catch {
            return nil
        }
    }

    /// Trims optional strings and converts blank values into `nil`.
    private func normalizedValue(_ value: String?) -> String? {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmedValue.isEmpty else {
            return nil
        }

        return trimmedValue
    }
}

private extension UIApplication {
    /// Finds the foreground UIKit presenter needed by the Google Sign-In SDK.
    func ortioTopViewController() -> UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController?
            .ortioTopPresentedViewController()
    }
}

private extension UIViewController {
    /// Walks through container and presented controllers to find the visible presenter.
    func ortioTopPresentedViewController() -> UIViewController {
        if let navigationController = self as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.ortioTopPresentedViewController()
        }

        if let tabBarController = self as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.ortioTopPresentedViewController()
        }

        if let presentedViewController {
            return presentedViewController.ortioTopPresentedViewController()
        }

        return self
    }
}
