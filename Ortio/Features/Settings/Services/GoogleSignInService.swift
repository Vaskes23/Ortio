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
    let email: String
    let fullName: String?
    let avatarData: Data?
}

/// Errors surfaced by the Google Sign-In setup before or during OAuth.
enum GoogleSignInServiceError: LocalizedError, Equatable {
    case missingClientID
    case missingURLScheme
    case missingPresenter
    case missingProfileEmail

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
    func signIn() async throws -> GoogleAccountProfile
    func restorePreviousSignIn() async throws -> GoogleAccountProfile?
}

/// Production Google Sign-In implementation.
@MainActor
final class GoogleSignInService: GoogleSignInServicing {
    func signIn() async throws -> GoogleAccountProfile {
        try configureFromBundle()

        guard let presenter = UIApplication.shared.ortioTopViewController() else {
            throw GoogleSignInServiceError.missingPresenter
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        return try await profile(from: result.user)
    }

    func restorePreviousSignIn() async throws -> GoogleAccountProfile? {
        try configureFromBundle()

        do {
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            return try await profile(from: user)
        } catch {
            return nil
        }
    }

    private func configureFromBundle() throws {
        let clientID = try requiredBundleValue(for: "GIDClientID", missingError: .missingClientID)
        _ = try requiredBundleValue(for: "GoogleSignInURLScheme", missingError: .missingURLScheme)
        let serverClientID = optionalBundleValue(for: "GIDServerClientID")

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: clientID,
            serverClientID: serverClientID
        )
    }

    private func requiredBundleValue(
        for key: String,
        missingError: GoogleSignInServiceError
    ) throws -> String {
        guard let value = optionalBundleValue(for: key) else {
            throw missingError
        }

        return value
    }

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

    private func normalizedValue(_ value: String?) -> String? {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmedValue.isEmpty else {
            return nil
        }

        return trimmedValue
    }
}

private extension UIApplication {
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
