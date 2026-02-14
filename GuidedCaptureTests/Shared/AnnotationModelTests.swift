//
//  AnnotationModelTests.swift
//  GuidedCaptureTests
//
//  Tests for the Annotation SwiftData model
//

import XCTest
import SwiftData
@testable import GuidedCaptureShared

@MainActor
final class AnnotationModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        // Create in-memory container for testing
        let schema = Schema([Annotation.self, Models.self, User.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: configuration)
        context = ModelContext(container)
    }

    override func tearDown() {
        container = nil
        context = nil
    }

    // MARK: - Initialization Tests

    func testAnnotationInitialization() throws {
        // Arrange
        let modelId = UUID()
        let authorId = UUID()
        let title = "Corner Issue"
        let content = "This corner needs adjustment"

        // Act
        let annotation = Annotation(
            modelId: modelId,
            authorId: authorId,
            positionX: 1.0,
            positionY: 2.0,
            positionZ: 3.0,
            rotationX: 0.0,
            rotationY: 0.0,
            rotationZ: 0.0,
            rotationW: 1.0,
            title: title,
            content: content
        )

        // Assert
        XCTAssertNotNil(annotation.id)
        XCTAssertEqual(annotation.modelId, modelId)
        XCTAssertEqual(annotation.authorId, authorId)
        XCTAssertEqual(annotation.positionX, 1.0)
        XCTAssertEqual(annotation.positionY, 2.0)
        XCTAssertEqual(annotation.positionZ, 3.0)
        XCTAssertEqual(annotation.rotationX, 0.0)
        XCTAssertEqual(annotation.rotationY, 0.0)
        XCTAssertEqual(annotation.rotationZ, 0.0)
        XCTAssertEqual(annotation.rotationW, 1.0)
        XCTAssertEqual(annotation.title, title)
        XCTAssertEqual(annotation.content, content)
        XCTAssertEqual(annotation.syncStatus, .pending)
    }

    #if canImport(simd)
    func testAnnotationConvenienceInitWithSIMD() throws {
        // Arrange
        let modelId = UUID()
        let authorId = UUID()
        let position = SIMD3<Float>(1.0, 2.0, 3.0)
        let rotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
        let title = "Test Annotation"
        let content = "Test content"

        // Act
        let annotation = Annotation(
            modelId: modelId,
            authorId: authorId,
            position: position,
            rotation: rotation,
            title: title,
            content: content
        )

        // Assert
        XCTAssertEqual(annotation.positionX, position.x)
        XCTAssertEqual(annotation.positionY, position.y)
        XCTAssertEqual(annotation.positionZ, position.z)
        XCTAssertEqual(annotation.rotationX, rotation.vector.x)
        XCTAssertEqual(annotation.rotationY, rotation.vector.y)
        XCTAssertEqual(annotation.rotationZ, rotation.vector.z)
        XCTAssertEqual(annotation.rotationW, rotation.vector.w)
    }

    func testAnnotationPositionProperty() throws {
        // Arrange
        let annotation = Annotation(
            modelId: UUID(),
            authorId: UUID(),
            positionX: 5.0,
            positionY: 10.0,
            positionZ: 15.0,
            rotationX: 0.0,
            rotationY: 0.0,
            rotationZ: 0.0,
            rotationW: 1.0,
            title: "Test",
            content: "Test"
        )

        // Act
        let position = annotation.position

        // Assert
        XCTAssertEqual(position.x, 5.0)
        XCTAssertEqual(position.y, 10.0)
        XCTAssertEqual(position.z, 15.0)
    }

    func testAnnotationRotationProperty() throws {
        // Arrange
        let rotation = simd_quatf(angle: Float.pi / 2, axis: SIMD3<Float>(0, 1, 0))
        let annotation = Annotation(
            modelId: UUID(),
            authorId: UUID(),
            positionX: 0.0,
            positionY: 0.0,
            positionZ: 0.0,
            rotationX: rotation.vector.x,
            rotationY: rotation.vector.y,
            rotationZ: rotation.vector.z,
            rotationW: rotation.vector.w,
            title: "Test",
            content: "Test"
        )

        // Act
        let retrievedRotation = annotation.rotation

        // Assert
        XCTAssertEqual(retrievedRotation.vector.x, rotation.vector.x, accuracy: 0.0001)
        XCTAssertEqual(retrievedRotation.vector.y, rotation.vector.y, accuracy: 0.0001)
        XCTAssertEqual(retrievedRotation.vector.z, rotation.vector.z, accuracy: 0.0001)
        XCTAssertEqual(retrievedRotation.vector.w, rotation.vector.w, accuracy: 0.0001)
    }
    #endif

    // MARK: - Persistence Tests

    func testAnnotationPersistence() throws {
        // Arrange
        let annotation = Annotation(
            modelId: UUID(),
            authorId: UUID(),
            positionX: 1.0,
            positionY: 2.0,
            positionZ: 3.0,
            rotationX: 0.0,
            rotationY: 0.0,
            rotationZ: 0.0,
            rotationW: 1.0,
            title: "Test Annotation",
            content: "Test content"
        )

        // Act - Insert
        context.insert(annotation)
        try context.save()

        // Assert - Fetch
        let descriptor = FetchDescriptor<Annotation>()
        let fetchedAnnotations = try context.fetch(descriptor)

        XCTAssertEqual(fetchedAnnotations.count, 1)
        XCTAssertEqual(fetchedAnnotations.first?.id, annotation.id)
        XCTAssertEqual(fetchedAnnotations.first?.title, "Test Annotation")
    }

    func testAnnotationUpdate() throws {
        // Arrange
        let annotation = Annotation(
            modelId: UUID(),
            authorId: UUID(),
            positionX: 1.0,
            positionY: 2.0,
            positionZ: 3.0,
            rotationX: 0.0,
            rotationY: 0.0,
            rotationZ: 0.0,
            rotationW: 1.0,
            title: "Original Title",
            content: "Original Content"
        )
        context.insert(annotation)
        try context.save()

        // Act - Update
        annotation.title = "Updated Title"
        annotation.content = "Updated Content"
        annotation.updatedAt = Date()
        try context.save()

        // Assert
        let descriptor = FetchDescriptor<Annotation>()
        let fetchedAnnotations = try context.fetch(descriptor)

        XCTAssertEqual(fetchedAnnotations.first?.title, "Updated Title")
        XCTAssertEqual(fetchedAnnotations.first?.content, "Updated Content")
        XCTAssertGreaterThan(fetchedAnnotations.first?.updatedAt ?? Date(), annotation.createdAt)
    }

    func testAnnotationDeletion() throws {
        // Arrange
        let annotation = Annotation(
            modelId: UUID(),
            authorId: UUID(),
            positionX: 1.0,
            positionY: 2.0,
            positionZ: 3.0,
            rotationX: 0.0,
            rotationY: 0.0,
            rotationZ: 0.0,
            rotationW: 1.0,
            title: "To Delete",
            content: "Will be deleted"
        )
        context.insert(annotation)
        try context.save()

        // Act - Delete
        context.delete(annotation)
        try context.save()

        // Assert
        let descriptor = FetchDescriptor<Annotation>()
        let fetchedAnnotations = try context.fetch(descriptor)

        XCTAssertEqual(fetchedAnnotations.count, 0)
    }

    // MARK: - Sync Status Tests

    func testSyncStatusDefaultsToending() throws {
        // Arrange & Act
        let annotation = Annotation(
            modelId: UUID(),
            authorId: UUID(),
            positionX: 0.0,
            positionY: 0.0,
            positionZ: 0.0,
            rotationX: 0.0,
            rotationY: 0.0,
            rotationZ: 0.0,
            rotationW: 1.0,
            title: "Test",
            content: "Test"
        )

        // Assert
        XCTAssertEqual(annotation.syncStatus, .pending)
    }

    func testSyncStatusCanBeUpdated() throws {
        // Arrange
        let annotation = Annotation(
            modelId: UUID(),
            authorId: UUID(),
            positionX: 0.0,
            positionY: 0.0,
            positionZ: 0.0,
            rotationX: 0.0,
            rotationY: 0.0,
            rotationZ: 0.0,
            rotationW: 1.0,
            title: "Test",
            content: "Test"
        )
        context.insert(annotation)
        try context.save()

        // Act - Update status to synced
        annotation.syncStatus = .synced
        try context.save()

        // Assert
        let descriptor = FetchDescriptor<Annotation>()
        let fetchedAnnotations = try context.fetch(descriptor)

        XCTAssertEqual(fetchedAnnotations.first?.syncStatus, .synced)
    }

    // MARK: - Query Tests

    func testFetchAnnotationsByModelId() throws {
        // Arrange
        let modelId = UUID()
        let otherModelId = UUID()
        let authorId = UUID()

        let annotation1 = Annotation(modelId: modelId, authorId: authorId,
                                    positionX: 0, positionY: 0, positionZ: 0,
                                    rotationX: 0, rotationY: 0, rotationZ: 0, rotationW: 1,
                                    title: "Annotation 1", content: "Content 1")
        let annotation2 = Annotation(modelId: modelId, authorId: authorId,
                                    positionX: 1, positionY: 1, positionZ: 1,
                                    rotationX: 0, rotationY: 0, rotationZ: 0, rotationW: 1,
                                    title: "Annotation 2", content: "Content 2")
        let annotation3 = Annotation(modelId: otherModelId, authorId: authorId,
                                    positionX: 2, positionY: 2, positionZ: 2,
                                    rotationX: 0, rotationY: 0, rotationZ: 0, rotationW: 1,
                                    title: "Other Model", content: "Content 3")

        context.insert(annotation1)
        context.insert(annotation2)
        context.insert(annotation3)
        try context.save()

        // Act
        let predicate = #Predicate<Annotation> { $0.modelId == modelId }
        let descriptor = FetchDescriptor<Annotation>(predicate: predicate)
        let fetchedAnnotations = try context.fetch(descriptor)

        // Assert
        XCTAssertEqual(fetchedAnnotations.count, 2)
        XCTAssertTrue(fetchedAnnotations.allSatisfy { $0.modelId == modelId })
    }

    func testFetchAnnotationsByAuthorId() throws {
        // Arrange
        let modelId = UUID()
        let authorId1 = UUID()
        let authorId2 = UUID()

        let annotation1 = Annotation(modelId: modelId, authorId: authorId1,
                                    positionX: 0, positionY: 0, positionZ: 0,
                                    rotationX: 0, rotationY: 0, rotationZ: 0, rotationW: 1,
                                    title: "Author 1", content: "Content 1")
        let annotation2 = Annotation(modelId: modelId, authorId: authorId2,
                                    positionX: 1, positionY: 1, positionZ: 1,
                                    rotationX: 0, rotationY: 0, rotationZ: 0, rotationW: 1,
                                    title: "Author 2", content: "Content 2")

        context.insert(annotation1)
        context.insert(annotation2)
        try context.save()

        // Act
        let predicate = #Predicate<Annotation> { $0.authorId == authorId1 }
        let descriptor = FetchDescriptor<Annotation>(predicate: predicate)
        let fetchedAnnotations = try context.fetch(descriptor)

        // Assert
        XCTAssertEqual(fetchedAnnotations.count, 1)
        XCTAssertEqual(fetchedAnnotations.first?.authorId, authorId1)
    }

    func testFetchPendingAnnotations() throws {
        // Arrange
        let modelId = UUID()
        let authorId = UUID()

        let pendingAnnotation = Annotation(modelId: modelId, authorId: authorId,
                                         positionX: 0, positionY: 0, positionZ: 0,
                                         rotationX: 0, rotationY: 0, rotationZ: 0, rotationW: 1,
                                         title: "Pending", content: "Content")
        let syncedAnnotation = Annotation(modelId: modelId, authorId: authorId,
                                        positionX: 1, positionY: 1, positionZ: 1,
                                        rotationX: 0, rotationY: 0, rotationZ: 0, rotationW: 1,
                                        title: "Synced", content: "Content",
                                        syncStatus: .synced)

        context.insert(pendingAnnotation)
        context.insert(syncedAnnotation)
        try context.save()

        // Act
        let predicate = #Predicate<Annotation> { $0.syncStatus == .pending }
        let descriptor = FetchDescriptor<Annotation>(predicate: predicate)
        let fetchedAnnotations = try context.fetch(descriptor)

        // Assert
        XCTAssertEqual(fetchedAnnotations.count, 1)
        XCTAssertEqual(fetchedAnnotations.first?.syncStatus, .pending)
    }
}
