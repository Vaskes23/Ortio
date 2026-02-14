//
//  UserRecord.swift
//  GuidedCaptureShared
//
//  Data Transfer Object (DTO) for user data from cloud backend
//

import Foundation

/// Represents a user in the cloud database.
/// This is separate from the SwiftData `User` entity (which stores local preferences).
struct UserRecord: Codable, Identifiable {
    /// Unique identifier for the user
    let id: UUID

    /// Unique username
    let username: String

    /// User's display name
    let name: String

    /// URL to profile image in cloud storage (optional)
    let profileImageUrl: String?

    /// When the user account was created
    let createdAt: Date

    /// Session token for authenticated requests (ephemeral, not stored in DB)
    var sessionToken: String?

    // MARK: - Codable Keys

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case name
        case profileImageUrl = "profile_image_url"
        case createdAt = "created_at"
        case sessionToken = "session_token"
    }
}

// MARK: - Convenience Extensions

extension UserRecord {
    /// Convert to SwiftData User entity
    /// - Returns: User instance for SwiftData persistence
    func toSwiftDataUser(theme: Theme = .system, profileImage: Data? = nil) -> User {
        User(
            username: username,
            name: name,
            theme: theme,
            profileImage: profileImage
        )
    }
}
