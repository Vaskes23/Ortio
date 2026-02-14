//
//  User.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 22.06.2024.
//

import Foundation
import SwiftData
import UIKit

/// SwiftData model for user profile and preferences.
/// Stores name, username, theme choice, and an optional profile photo.
@Model
final class User {
    @Attribute(.unique) var username: String
    @Attribute var name: String
    var theme: Theme
    @Attribute(.externalStorage) var profileImage: Data?

    init(username: String, name: String, theme: Theme, profileImage: Data?) {
        self.username = username
        self.name = name
        self.theme = theme
        self.profileImage = profileImage
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

    func updateProfileImage(_ image: UIImage) {
        self.profileImage = image.jpegData(compressionQuality: 0.8)
    }
}
