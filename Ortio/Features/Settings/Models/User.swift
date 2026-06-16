//
//  User.swift
//  Ortio
//
//  Created by Matyas Vascak on 22.06.2024.
//

import Foundation
import SwiftData
import UIKit

/// SwiftData model for user profile, preferences, and compact account identity.
/// Stores only the provider identifier and optional profile fields needed to
/// unlock account-owned settings locally.
@Model
final class User {
    /// User-editable handle displayed under the profile name.
    @Attribute(.unique) var username: String

    /// User-editable display name shown in settings and profile surfaces.
    @Attribute var name: String

    /// Persisted appearance preference for this profile.
    var theme: Theme

    /// Optional local avatar bytes. External storage avoids bloating the main SwiftData row.
    @Attribute(.externalStorage) var profileImage: Data?

    /// Account provider that unlocked profile editing, such as `"apple"` or `"google"`.
    var accountProvider: String?

    /// Stable Apple user identifier. Only populated for Apple sign-in.
    var appleUserIdentifier: String?

    /// Normalized account email when a provider returns one. Google sign-in uses this as its local account key.
    var accountEmail: String?

    /// Local timestamp for when account sign-in last completed.
    var signedInAt: Date?

    /// Creates a profile record with optional compact account identity fields.
    init(
        username: String,
        name: String,
        theme: Theme,
        profileImage: Data?,
        accountProvider: String? = nil,
        appleUserIdentifier: String? = nil,
        accountEmail: String? = nil,
        signedInAt: Date? = nil
    ) {
        self.username = username
        self.name = name
        self.theme = theme
        self.profileImage = profileImage
        self.accountProvider = accountProvider
        self.appleUserIdentifier = appleUserIdentifier
        self.accountEmail = accountEmail
        self.signedInAt = signedInAt
    }

    /// Creates the locked placeholder profile shown before account sign-in.
    convenience init() {
        self.init(username: "placeholder", name: "Placeholder User", theme: .light, profileImage: Data())
    }

    /// Decoded profile image for SwiftUI rendering.
    var profileUIImage: UIImage? {
        if let data = profileImage {
            return UIImage(data: data)
        }
        return nil
    }

    /// Whether the user unlocked account settings through Apple Sign-In.
    var isSignedInWithApple: Bool {
        accountProvider == "apple" && appleUserIdentifier?.isEmpty == false
    }

    /// Whether the user unlocked account settings through Google Sign-In.
    var isSignedInWithGoogle: Bool {
        accountProvider == "google" && accountEmail?.isEmpty == false
    }

    /// Whether any supported account provider has unlocked profile editing and settings.
    var isAuthenticated: Bool {
        isSignedInWithApple || isSignedInWithGoogle
    }

    /// Replaces the local avatar using compact JPEG data.
    func updateProfileImage(_ image: UIImage) {
        self.profileImage = image.jpegData(compressionQuality: 0.8)
    }
}
