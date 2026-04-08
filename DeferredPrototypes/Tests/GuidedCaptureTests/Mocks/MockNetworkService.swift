//
//  MockNetworkService.swift
//  GuidedCaptureTests
//
//  Mock implementation of NetworkProtocol for testing
//

import Foundation
@testable import GuidedCaptureShared

/// Mock network service for testing without real network calls.
/// Follows the pattern established by MockFileManager.
final class MockNetworkService: NetworkProtocol {
    // MARK: - Call Tracking

    var signUpCallCount = 0
    var signInCallCount = 0
    var signOutCallCount = 0
    var uploadModelCallCount = 0
    var downloadModelCallCount = 0
    var fetchModelsCallCount = 0
    var deleteModelCallCount = 0
    var uploadAnnotationCallCount = 0
    var fetchAnnotationsCallCount = 0
    var updateAnnotationCallCount = 0
    var deleteAnnotationCallCount = 0
    var shareModelCallCount = 0
    var fetchSharedModelsCallCount = 0
    var unshareModelCallCount = 0

    // MARK: - Stubs (configure these in tests)

    var signUpStub: ((String, String) async throws -> UserRecord)?
    var signInStub: ((String, String) async throws -> UserRecord)?
    var signOutStub: (() async throws -> Void)?
    var currentUserStub: (() async -> UserRecord?)?
    var uploadModelStub: ((URL, UUID, UUID) async throws -> String)?
    var downloadModelStub: ((UUID, URL) async throws -> Void)?
    var fetchModelsStub: ((UUID) async throws -> [ModelRecord])?
    var deleteModelStub: ((UUID) async throws -> Void)?
    var uploadAnnotationStub: ((AnnotationRecord) async throws -> Void)?
    var fetchAnnotationsStub: ((UUID) async throws -> [AnnotationRecord])?
    var updateAnnotationStub: ((AnnotationRecord) async throws -> Void)?
    var deleteAnnotationStub: ((UUID) async throws -> Void)?
    var shareModelStub: ((UUID, String, SharePermission) async throws -> Void)?
    var fetchSharedModelsStub: ((UUID) async throws -> [ModelRecord])?
    var unshareModelStub: ((UUID, UUID) async throws -> Void)?

    // MARK: - In-Memory Storage (for simple tests)

    private var mockCurrentUser: UserRecord?
    private var mockModels: [ModelRecord] = []
    private var mockAnnotations: [AnnotationRecord] = []
    private var mockShares: [(modelId: UUID, userId: UUID, permission: SharePermission)] = []

    // MARK: - Authentication

    func signUp(email: String, password: String) async throws -> UserRecord {
        signUpCallCount += 1

        if let stub = signUpStub {
            return try await stub(email, password)
        }

        // Default behavior: create mock user
        let user = UserRecord(
            id: UUID(),
            username: email.components(separatedBy: "@").first ?? "user",
            name: "Test User",
            profileImageUrl: nil,
            createdAt: Date(),
            sessionToken: "mock-token-\(UUID().uuidString)"
        )
        mockCurrentUser = user
        return user
    }

    func signIn(email: String, password: String) async throws -> UserRecord {
        signInCallCount += 1

        if let stub = signInStub {
            return try await stub(email, password)
        }

        // Default behavior: mock signin
        let user = UserRecord(
            id: UUID(),
            username: email.components(separatedBy: "@").first ?? "user",
            name: "Test User",
            profileImageUrl: nil,
            createdAt: Date(),
            sessionToken: "mock-token-\(UUID().uuidString)"
        )
        mockCurrentUser = user
        return user
    }

    func signOut() async throws {
        signOutCallCount += 1

        if let stub = signOutStub {
            try await stub()
            return
        }

        mockCurrentUser = nil
    }

    func currentUser() async -> UserRecord? {
        if let stub = currentUserStub {
            return await stub()
        }
        return mockCurrentUser
    }

    // MARK: - Model Operations

    func uploadModel(localURL: URL, modelId: UUID, userId: UUID) async throws -> String {
        uploadModelCallCount += 1

        if let stub = uploadModelStub {
            return try await stub(localURL, modelId, userId)
        }

        // Default behavior: mock upload
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: localURL.path)[.size] as? Int64) ?? 0
        let mockURL = "https://mock.supabase.co/storage/models/\(modelId).usdz"

        let model = ModelRecord(
            id: modelId,
            ownerId: userId,
            name: localURL.lastPathComponent,
            fileUrl: mockURL,
            fileSize: fileSize,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockModels.append(model)

        return mockURL
    }

    func downloadModel(modelId: UUID, toLocalURL: URL) async throws {
        downloadModelCallCount += 1

        if let stub = downloadModelStub {
            try await stub(modelId, toLocalURL)
            return
        }

        // Default behavior: create empty file
        FileManager.default.createFile(atPath: toLocalURL.path, contents: Data())
    }

    func fetchModels(for userId: UUID) async throws -> [ModelRecord] {
        fetchModelsCallCount += 1

        if let stub = fetchModelsStub {
            return try await stub(userId)
        }

        return mockModels.filter { $0.ownerId == userId }
    }

    func deleteModel(modelId: UUID) async throws {
        deleteModelCallCount += 1

        if let stub = deleteModelStub {
            try await stub(modelId)
            return
        }

        mockModels.removeAll { $0.id == modelId }
    }

    // MARK: - Annotation Operations

    func uploadAnnotation(_ annotation: AnnotationRecord) async throws {
        uploadAnnotationCallCount += 1

        if let stub = uploadAnnotationStub {
            try await stub(annotation)
            return
        }

        mockAnnotations.append(annotation)
    }

    func fetchAnnotations(for modelId: UUID) async throws -> [AnnotationRecord] {
        fetchAnnotationsCallCount += 1

        if let stub = fetchAnnotationsStub {
            return try await stub(modelId)
        }

        return mockAnnotations.filter { $0.modelId == modelId }
    }

    func updateAnnotation(_ annotation: AnnotationRecord) async throws {
        updateAnnotationCallCount += 1

        if let stub = updateAnnotationStub {
            try await stub(annotation)
            return
        }

        if let index = mockAnnotations.firstIndex(where: { $0.id == annotation.id }) {
            mockAnnotations[index] = annotation
        }
    }

    func deleteAnnotation(annotationId: UUID) async throws {
        deleteAnnotationCallCount += 1

        if let stub = deleteAnnotationStub {
            try await stub(annotationId)
            return
        }

        mockAnnotations.removeAll { $0.id == annotationId }
    }

    // MARK: - Sharing Operations

    func shareModel(modelId: UUID, withUserEmail userEmail: String, permission: SharePermission) async throws {
        shareModelCallCount += 1

        if let stub = shareModelStub {
            try await stub(modelId, userEmail, permission)
            return
        }

        let mockUserId = UUID() // Mock user lookup
        mockShares.append((modelId, mockUserId, permission))
    }

    func fetchSharedModels(for userId: UUID) async throws -> [ModelRecord] {
        fetchSharedModelsCallCount += 1

        if let stub = fetchSharedModelsStub {
            return try await stub(userId)
        }

        let sharedModelIds = mockShares
            .filter { $0.userId == userId }
            .map { $0.modelId }

        return mockModels.filter { sharedModelIds.contains($0.id) }
    }

    func unshareModel(modelId: UUID, fromUser userId: UUID) async throws {
        unshareModelCallCount += 1

        if let stub = unshareModelStub {
            try await stub(modelId, userId)
            return
        }

        mockShares.removeAll { $0.modelId == modelId && $0.userId == userId }
    }

    // MARK: - Test Helpers

    /// Reset all call counts and clear mock data
    func reset() {
        signUpCallCount = 0
        signInCallCount = 0
        signOutCallCount = 0
        uploadModelCallCount = 0
        downloadModelCallCount = 0
        fetchModelsCallCount = 0
        deleteModelCallCount = 0
        uploadAnnotationCallCount = 0
        fetchAnnotationsCallCount = 0
        updateAnnotationCallCount = 0
        deleteAnnotationCallCount = 0
        shareModelCallCount = 0
        fetchSharedModelsCallCount = 0
        unshareModelCallCount = 0

        mockCurrentUser = nil
        mockModels.removeAll()
        mockAnnotations.removeAll()
        mockShares.removeAll()
    }
}
