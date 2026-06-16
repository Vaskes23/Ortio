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
    @Attribute(.unique) var username: String
    @Attribute var name: String
    var theme: Theme
    @Attribute(.externalStorage) var profileImage: Data?
    var accountProvider: String?
    var appleUserIdentifier: String?
    var accountEmail: String?
    var signedInAt: Date?

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

    convenience init() {
        self.init(username: "placeholder", name: "Placeholder User", theme: .light, profileImage: Data())
    }

    var profileUIImage: UIImage? {
        if let data = profileImage {
            return UIImage(data: data)
        }
        return nil
    }

    var isSignedInWithApple: Bool {
        accountProvider == "apple" && appleUserIdentifier?.isEmpty == false
    }

    var isSignedInWithGoogle: Bool {
        accountProvider == "google" && accountEmail?.isEmpty == false
    }

    var isAuthenticated: Bool {
        isSignedInWithApple || isSignedInWithGoogle
    }

    func updateProfileImage(_ image: UIImage) {
        self.profileImage = image.jpegData(compressionQuality: 0.8)
    }
}
