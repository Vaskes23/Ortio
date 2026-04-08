//
//  ModelRecord.swift
//  GuidedCaptureShared
//
//  Data Transfer Object (DTO) for model metadata from cloud backend
//

import Foundation

/// Represents a 3D model's metadata in the cloud database.
/// This is a lightweight DTO, separate from the SwiftData `Models` entity.
struct ModelRecord: Codable, Identifiable {
    /// Unique identifier matching SwiftData Models.id
    let id: UUID

    /// User ID of the model owner
    let ownerId: UUID

    /// Display name for the model
    let name: String

    /// Cloud storage URL for the USDZ file
    let fileUrl: String

    /// File size in bytes
    let fileSize: Int64

    /// When the model was created
    let createdAt: Date

    /// When the model was last updated
    let updatedAt: Date

    // MARK: - Codable Keys

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case name
        case fileUrl = "file_url"
        case fileSize = "file_size"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Convenience Extensions

extension ModelRecord {
    /// Convert to SwiftData Models entity
    /// - Parameter localURL: Local file path where USDZ is stored
    /// - Returns: Models instance for SwiftData persistence
    func toSwiftDataModel(localURL: URL) -> Models {
        Models(
            name: name,
            date: createdAt,
            favorite: false,
            imported: true,
            size: Double(fileSize),
            model: localURL
        )
    }
}

extension Models {
    /// Convert SwiftData Models entity to cloud DTO
    /// - Parameter ownerId: ID of the user who owns this model
    /// - Returns: ModelRecord for cloud upload
    func toModelRecord(ownerId: UUID, fileUrl: String) -> ModelRecord {
        ModelRecord(
            id: UUID(), // Generate new ID for cloud record
            ownerId: ownerId,
            name: name,
            fileUrl: fileUrl,
            fileSize: Int64(size),
            createdAt: date,
            updatedAt: date
        )
    }
}
