//
//  AnnotationRecord.swift
//  GuidedCaptureShared
//
//  Data Transfer Object (DTO) for annotations from cloud backend
//

import Foundation

/// Represents an annotation in the cloud database.
/// This is a lightweight DTO, separate from the SwiftData `Annotation` entity.
struct AnnotationRecord: Codable, Identifiable {
    /// Unique identifier matching SwiftData Annotation.id
    let id: UUID

    /// Foreign key to the model this annotation belongs to
    let modelId: UUID

    /// Foreign key to the user who created this annotation
    let authorId: UUID

    // MARK: - Position (model-relative)

    let positionX: Float
    let positionY: Float
    let positionZ: Float

    // MARK: - Rotation (quaternion)

    let rotationX: Float
    let rotationY: Float
    let rotationZ: Float
    let rotationW: Float

    // MARK: - Content

    let title: String
    let content: String

    // MARK: - Timestamps

    let createdAt: Date
    let updatedAt: Date

    // MARK: - Codable Keys

    enum CodingKeys: String, CodingKey {
        case id
        case modelId = "model_id"
        case authorId = "author_id"
        case positionX = "position_x"
        case positionY = "position_y"
        case positionZ = "position_z"
        case rotationX = "rotation_x"
        case rotationY = "rotation_y"
        case rotationZ = "rotation_z"
        case rotationW = "rotation_w"
        case title
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Convenience Extensions

extension AnnotationRecord {
    /// Convert to SwiftData Annotation entity
    /// - Returns: Annotation instance for SwiftData persistence
    func toSwiftDataAnnotation() -> Annotation {
        Annotation(
            id: id,
            modelId: modelId,
            authorId: authorId,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            rotationX: rotationX,
            rotationY: rotationY,
            rotationZ: rotationZ,
            rotationW: rotationW,
            title: title,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: .synced // From cloud, so it's synced
        )
    }
}

extension Annotation {
    /// Convert SwiftData Annotation entity to cloud DTO
    /// - Returns: AnnotationRecord for cloud upload
    func toAnnotationRecord() -> AnnotationRecord {
        AnnotationRecord(
            id: id,
            modelId: modelId,
            authorId: authorId,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            rotationX: rotationX,
            rotationY: rotationY,
            rotationZ: rotationZ,
            rotationW: rotationW,
            title: title,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
