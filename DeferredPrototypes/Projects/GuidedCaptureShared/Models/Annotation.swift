//
//  Annotation.swift
//  GuidedCaptureShared
//
//  Created for Ortio XR system
//

import Foundation
import SwiftData

/// SwiftData model for spatial annotations on 3D models.
/// Coordinates are stored relative to the model origin (not world space).
@Model
final class Annotation: Identifiable {
    /// Unique identifier for this annotation
    var id: UUID

    /// Foreign key to the Models entity this annotation belongs to
    var modelId: UUID

    /// Foreign key to the User who created this annotation
    var authorId: UUID

    // MARK: - Position (model-relative coordinates)

    /// X coordinate relative to model origin
    var positionX: Float

    /// Y coordinate relative to model origin
    var positionY: Float

    /// Z coordinate relative to model origin
    var positionZ: Float

    // MARK: - Rotation (quaternion representation)

    /// Quaternion X component
    var rotationX: Float

    /// Quaternion Y component
    var rotationY: Float

    /// Quaternion Z component
    var rotationZ: Float

    /// Quaternion W component (scalar)
    var rotationW: Float

    // MARK: - Content

    /// Short title for the annotation (max 50 characters recommended)
    var title: String

    /// Detailed content/description (max 500 characters recommended)
    var content: String

    // MARK: - Timestamps

    /// When this annotation was created
    var createdAt: Date

    /// When this annotation was last modified
    var updatedAt: Date

    // MARK: - Sync Status

    /// Current synchronization state with cloud backend
    var syncStatus: SyncStatus

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        modelId: UUID,
        authorId: UUID,
        positionX: Float,
        positionY: Float,
        positionZ: Float,
        rotationX: Float,
        rotationY: Float,
        rotationZ: Float,
        rotationW: Float,
        title: String,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.modelId = modelId
        self.authorId = authorId
        self.positionX = positionX
        self.positionY = positionY
        self.positionZ = positionZ
        self.rotationX = rotationX
        self.rotationY = rotationY
        self.rotationZ = rotationZ
        self.rotationW = rotationW
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}

// MARK: - Sync Status

/// Represents the synchronization state of an annotation with the cloud backend
enum SyncStatus: String, Codable, CaseIterable {
    /// Annotation created locally, not yet uploaded to cloud
    case pending

    /// Successfully synchronized with cloud
    case synced

    /// Upload/sync failed, will retry
    case failed
}

// MARK: - Convenience Extensions

#if canImport(simd)
import simd

extension Annotation {
    /// Convenience initializer using SIMD3 for position
    convenience init(
        id: UUID = UUID(),
        modelId: UUID,
        authorId: UUID,
        position: SIMD3<Float>,
        rotationX: Float,
        rotationY: Float,
        rotationZ: Float,
        rotationW: Float,
        title: String,
        content: String
    ) {
        self.init(
            id: id,
            modelId: modelId,
            authorId: authorId,
            positionX: position.x,
            positionY: position.y,
            positionZ: position.z,
            rotationX: rotationX,
            rotationY: rotationY,
            rotationZ: rotationZ,
            rotationW: rotationW,
            title: title,
            content: content
        )
    }

    /// Convenience initializer using SIMD3 for position and simd_quatf for rotation
    convenience init(
        id: UUID = UUID(),
        modelId: UUID,
        authorId: UUID,
        position: SIMD3<Float>,
        rotation: simd_quatf,
        title: String,
        content: String
    ) {
        self.init(
            id: id,
            modelId: modelId,
            authorId: authorId,
            positionX: position.x,
            positionY: position.y,
            positionZ: position.z,
            rotationX: rotation.vector.x,
            rotationY: rotation.vector.y,
            rotationZ: rotation.vector.z,
            rotationW: rotation.vector.w,
            title: title,
            content: content
        )
    }

    /// Get position as SIMD3 vector
    var position: SIMD3<Float> {
        SIMD3<Float>(positionX, positionY, positionZ)
    }

    /// Get rotation as quaternion
    var rotation: simd_quatf {
        simd_quatf(vector: SIMD4<Float>(rotationX, rotationY, rotationZ, rotationW))
    }
}
#endif
