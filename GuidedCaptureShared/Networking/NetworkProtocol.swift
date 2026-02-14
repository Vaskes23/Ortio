//
//  NetworkProtocol.swift
//  GuidedCaptureShared
//
//  Protocol abstraction for cloud operations (following FileManagerProtocol pattern)
//

import Foundation

/// Protocol defining all cloud storage and synchronization operations.
/// Implementations can use Supabase, CloudKit, or other backends.
/// Mock implementations enable testing without network calls.
protocol NetworkProtocol {
    // MARK: - Authentication

    /// Sign up a new user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password (min 6 characters)
    /// - Returns: User record with ID and metadata
    /// - Throws: NetworkError if signup fails (email exists, weak password, etc.)
    func signUp(email: String, password: String) async throws -> UserRecord

    /// Sign in an existing user
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: User record with session token
    /// - Throws: NetworkError if credentials are invalid
    func signIn(email: String, password: String) async throws -> UserRecord

    /// Sign out the current user and clear session
    /// - Throws: NetworkError if sign out fails
    func signOut() async throws

    /// Get the currently authenticated user
    /// - Returns: UserRecord if signed in, nil otherwise
    func currentUser() async -> UserRecord?

    // MARK: - Model Operations

    /// Upload a USDZ model file to cloud storage
    /// - Parameters:
    ///   - localURL: Local file URL of the USDZ model
    ///   - modelId: Unique identifier for this model
    ///   - userId: ID of the user uploading the model
    /// - Returns: Public URL of the uploaded file
    /// - Throws: NetworkError if upload fails (network error, file too large, etc.)
    func uploadModel(localURL: URL, modelId: UUID, userId: UUID) async throws -> String

    /// Download a USDZ model file from cloud storage
    /// - Parameters:
    ///   - modelId: ID of the model to download
    ///   - toLocalURL: Destination URL for the downloaded file
    /// - Throws: NetworkError if download fails
    func downloadModel(modelId: UUID, toLocalURL: URL) async throws

    /// Fetch all models owned by or shared with a user
    /// - Parameter userId: User ID to fetch models for
    /// - Returns: Array of model records
    /// - Throws: NetworkError if fetch fails
    func fetchModels(for userId: UUID) async throws -> [ModelRecord]

    /// Delete a model and all associated data
    /// - Parameter modelId: ID of the model to delete
    /// - Throws: NetworkError if deletion fails
    func deleteModel(modelId: UUID) async throws

    // MARK: - Annotation Operations

    /// Upload an annotation to the cloud
    /// - Parameter annotation: Annotation to upload
    /// - Throws: NetworkError if upload fails
    func uploadAnnotation(_ annotation: AnnotationRecord) async throws

    /// Fetch all annotations for a specific model
    /// - Parameter modelId: ID of the model
    /// - Returns: Array of annotation records
    /// - Throws: NetworkError if fetch fails
    func fetchAnnotations(for modelId: UUID) async throws -> [AnnotationRecord]

    /// Update an existing annotation
    /// - Parameter annotation: Annotation with updated data
    /// - Throws: NetworkError if update fails
    func updateAnnotation(_ annotation: AnnotationRecord) async throws

    /// Delete an annotation
    /// - Parameter annotationId: ID of the annotation to delete
    /// - Throws: NetworkError if deletion fails
    func deleteAnnotation(annotationId: UUID) async throws

    // MARK: - Sharing Operations

    /// Share a model with another user
    /// - Parameters:
    ///   - modelId: ID of the model to share
    ///   - userEmail: Email of the user to share with
    ///   - permission: Access permission level
    /// - Throws: NetworkError if sharing fails
    func shareModel(modelId: UUID, withUserEmail userEmail: String, permission: SharePermission) async throws

    /// Fetch models shared with a user
    /// - Parameter userId: User ID
    /// - Returns: Array of shared model records
    /// - Throws: NetworkError if fetch fails
    func fetchSharedModels(for userId: UUID) async throws -> [ModelRecord]

    /// Remove sharing access for a user
    /// - Parameters:
    ///   - modelId: ID of the model
    ///   - userId: ID of the user to remove access from
    /// - Throws: NetworkError if removal fails
    func unshareModel(modelId: UUID, fromUser userId: UUID) async throws
}

// MARK: - Share Permission

/// Access permission levels for shared models
enum SharePermission: String, Codable, CaseIterable {
    /// Can view model and annotations (read-only)
    case view

    /// Can view and add annotations
    case annotate

    var description: String {
        switch self {
        case .view: "View"
        case .annotate: "View & Annotate"
        }
    }
}

// MARK: - Network Error

/// Errors that can occur during network operations
enum NetworkError: LocalizedError {
    case notAuthenticated
    case invalidCredentials
    case emailAlreadyExists
    case weakPassword
    case networkUnavailable
    case uploadFailed(reason: String)
    case downloadFailed(reason: String)
    case invalidResponse
    case notFound
    case unauthorized
    case serverError(statusCode: Int)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must sign in to perform this action"
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .weakPassword:
            return "Password must be at least 6 characters"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        case .downloadFailed(let reason):
            return "Download failed: \(reason)"
        case .invalidResponse:
            return "Invalid server response"
        case .notFound:
            return "Resource not found"
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .serverError(let code):
            return "Server error (code \(code))"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
