//
//  UserModel.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 22.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import SwiftData
import UIKit

@Model
final class User {
    @Attribute(.unique) var username: String
    @Attribute var name: String
    var appearance: Int
    @Attribute(.externalStorage) var profileImage: Data?

    init(username: String, name: String, appearance: Int, profileImage: Data?) {
        self.username = username
        self.name = name
        self.appearance = appearance
        self.profileImage = profileImage
    }
    
    convenience init() {
        self.init(username: "placeholder", name: "Placeholder User", appearance: 0, profileImage: Data())
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