> Historical note: this is an archived prototype plan for the deferred shared-framework and visionOS direction. The active repo is stabilized around the iOS app only.

# Ortio XR System - Implementation Plan (Broken into Parts)

## Overview
This document breaks down the full implementation plan into digestible parts for review. Each part is a complete, testable unit of work that builds upon previous parts.

---

## Part 1: Shared Framework Foundation
**Duration Estimate**: 1-2 days
**Dependencies**: None
**Risk Level**: Low

### Goals
- Create reusable code foundation shared between iOS and visionOS
- Establish patterns for cross-platform development
- Enable parallel development of both apps

### Deliverables

#### 1.1 Framework Structure
- [ ] Create `GuidedCaptureShared` framework target in Xcode
- [ ] Set up directory structure:
  ```
  /GuidedCaptureShared/
  ├── Models/
  ├── Networking/
  ├── Utilities/
  └── SupabaseModels/
  ```
- [ ] Configure framework Info.plist and module settings
- [ ] Link framework to iOS target

#### 1.2 Move Existing Models
- [ ] Move `Models.swift` → `/GuidedCaptureShared/Models/`
- [ ] Move `User.swift` → `/GuidedCaptureShared/Models/`
- [ ] Move `Theme.swift` → `/GuidedCaptureShared/Models/`
- [ ] Move `FileManagerProtocol.swift` → `/GuidedCaptureShared/Utilities/`
- [ ] Move `PathConstants.swift` → `/GuidedCaptureShared/Utilities/`

#### 1.3 Update iOS App Imports
- [ ] Add `import GuidedCaptureShared` to all iOS files using models
- [ ] Update test files to import framework
- [ ] Verify all tests still pass

#### 1.4 Create Annotation Model
**New File**: `/GuidedCaptureShared/Models/Annotation.swift`

```swift
import Foundation
import SwiftData

@Model
final class Annotation: Identifiable {
    var id: UUID
    var modelId: UUID  // Foreign key to Models
    var authorId: UUID // Foreign key to User

    // Position relative to model origin (model-space coordinates)
    var positionX: Float
    var positionY: Float
    var positionZ: Float

    // Rotation as quaternion
    var rotationX: Float
    var rotationY: Float
    var rotationZ: Float
    var rotationW: Float

    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    init(id: UUID = UUID(),
         modelId: UUID,
         authorId: UUID,
         position: SIMD3<Float>,
         rotation: simd_quatf,
         title: String,
         content: String) {
        self.id = id
        self.modelId = modelId
        self.authorId = authorId
        self.positionX = position.x
        self.positionY = position.y
        self.positionZ = position.z
        self.rotationX = rotation.vector.x
        self.rotationY = rotation.vector.y
        self.rotationZ = rotation.vector.z
        self.rotationW = rotation.vector.w
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncStatus = .pending
    }
}

enum SyncStatus: String, Codable {
    case pending  // Created locally, not yet uploaded
    case synced   // Successfully synced to cloud
    case failed   // Upload failed
}
```

#### 1.5 Write Tests
**New File**: `/GuidedCaptureTests/AnnotationModelTests.swift`
- Test annotation creation
- Test position/rotation conversions
- Test sync status transitions
- Test SwiftData persistence

### Success Criteria
- ✅ iOS app builds successfully with framework
- ✅ All existing tests pass
- ✅ Annotation model tests pass
- ✅ No regressions in iOS functionality

### Questions for Review
1. **Framework Naming**: Is `GuidedCaptureShared` acceptable, or prefer `OrtioCore`/`OrtioShared`?
2. **Annotation Fields**: Do we need additional metadata (e.g., color, priority, tags)?
3. **Sync Strategy**: Confirm model-relative coordinates vs world-space anchors?

---

## Part 2: visionOS App Scaffold
**Duration Estimate**: 2-3 days
**Dependencies**: Part 1
**Risk Level**: Medium (new platform)

### Goals
- Create functional visionOS app with navigation
- Establish visionOS-specific patterns
- Set up SwiftData and app lifecycle

### Deliverables

#### 2.1 Create visionOS Target
- [ ] Create `GuidedCaptureVision` target in Xcode (visionOS platform)
- [ ] Link `GuidedCaptureShared` framework
- [ ] Configure Info.plist for visionOS requirements
- [ ] Add app icon and assets catalog

#### 2.2 App Entry Point
**New File**: `/GuidedCaptureVision/GuidedCaptureVisionApp.swift`

```swift
import SwiftUI
import SwiftData
import GuidedCaptureShared

@main
struct GuidedCaptureVisionApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Models.self,
            User.self,
            Annotation.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

#### 2.3 Main Navigation
**New File**: `/GuidedCaptureVision/Views/ContentView.swift`

- TabView with 2 tabs:
  - **Browse**: Model browser (grid of downloaded/local models)
  - **Settings**: User settings and preferences
- Follow iOS app's navigation structure

#### 2.4 Placeholder Views
**New Files**:
- `/GuidedCaptureVision/Views/ModelBrowserView.swift` - Empty grid with "No models yet" message
- `/GuidedCaptureVision/Views/SettingsView.swift` - Basic settings UI
- `/GuidedCaptureVision/ViewModels/ModelBrowserViewModel.swift` - ViewModel scaffold

#### 2.5 Test on Simulator
- [ ] Build visionOS app
- [ ] Run on visionOS simulator
- [ ] Verify navigation works
- [ ] Verify SwiftData container initializes

### Success Criteria
- ✅ visionOS app launches without crashes
- ✅ Navigation between tabs works
- ✅ SwiftData models accessible (Models, User, Annotation)
- ✅ Settings view shows theme picker

### Questions for Review
1. **Navigation Pattern**: Tab-based or sidebar navigation for visionOS?
2. **Initial Focus**: Start with model browser or onboarding flow?
3. **Settings Scope**: What settings are needed initially (theme, profile, logout)?

---

## Part 3: RealityKit 3D Model Viewer
**Duration Estimate**: 3-4 days
**Dependencies**: Part 2
**Risk Level**: High (RealityKit complexity)

### Goals
- Load and display USDZ models in 3D
- Implement spatial gestures (scale, rotate, pan)
- Create immersive viewing experience

### Deliverables

#### 3.1 Model Loader Utility
**New File**: `/GuidedCaptureVision/RealityKit/ModelLoader.swift`

```swift
import RealityKit
import Foundation

actor ModelLoader {
    static let shared = ModelLoader()

    func loadModel(from url: URL) async throws -> Entity {
        let entity = try await Entity.load(contentsOf: url)
        return entity
    }
}
```

#### 3.2 ModelViewerView
**New File**: `/GuidedCaptureVision/Views/ModelViewerView.swift`

- RealityKit `RealityView` component
- Load USDZ from URL
- Configure lighting (IBL + directional light)
- Set up camera (default position and FOV)
- Center and scale model appropriately

#### 3.3 ModelViewerViewModel
**New File**: `/GuidedCaptureVision/ViewModels/ModelViewerViewModel.swift`

```swift
import SwiftUI
import RealityKit
import GuidedCaptureShared

@Observable
final class ModelViewerViewModel {
    var currentModel: Models?
    var modelEntity: Entity?
    var transform: Transform = Transform()
    var showAnnotations: Bool = true

    @ObservationIgnored private let fileManager: FileManagerProtocol

    init(fileManager: FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }

    @MainActor
    func loadModel(_ model: Models) async {
        // Load USDZ and configure scene
    }

    func resetTransform() {
        transform = Transform()
    }
}
```

#### 3.4 Gesture Recognizers
**New File**: `/GuidedCaptureVision/RealityKit/GestureHandler.swift`

- Pinch gesture → Scale model (min: 0.1x, max: 10x)
- Rotation gesture → Rotate around Y-axis
- Drag gesture → Reposition in 3D space

#### 3.5 Transform Persistence
- [ ] Add `savedTransform` field to `Models` SwiftData model
- [ ] Store scale, rotation, position on transform change
- [ ] Restore transform when model is reopened

#### 3.6 Sample Models for Testing
- [ ] Add 3-5 sample USDZ files to test bundle
- [ ] Include variety: small objects, architectural models, different scales

### Success Criteria
- ✅ USDZ models load and render correctly
- ✅ Lighting looks realistic (no harsh shadows)
- ✅ Gestures are responsive and intuitive
- ✅ Transform persists across app restarts
- ✅ Reset button restores default view

### Questions for Review
1. **Lighting Setup**: Use IBL only, or IBL + directional? Any specific environment maps?
2. **Scale Limits**: Are 0.1x-10x appropriate, or adjust based on use case?
3. **Default Camera**: What's the ideal starting distance/angle for architectural models?
4. **AR Mode**: Include AR immersive space in this part, or defer to later?

---

## Part 4: AR Immersive Mode (OPTIONAL)
**Duration Estimate**: 2-3 days
**Dependencies**: Part 3
**Risk Level**: High (requires hardware testing)

### Goals
- Place models in real-world environment
- Enable real-world scale viewing
- Support plane detection and anchoring

### Deliverables

#### 4.1 Immersive Space Setup
**New File**: `/GuidedCaptureVision/ImmersiveSpace/ARImmersiveView.swift`

- Create immersive space scene
- Enable ARKit session
- Configure plane detection (horizontal surfaces)

#### 4.2 World Anchor
- [ ] Detect floor/table planes
- [ ] Place model at tap location on detected plane
- [ ] Configure model scale for real-world proportions (e.g., 1:50 architectural scale)

#### 4.3 Mode Toggle
- [ ] Add "AR Mode" button to `ModelViewerView`
- [ ] Switch between window mode and immersive space
- [ ] Handle immersive space lifecycle correctly

#### 4.4 Testing
⚠️ **Requires physical visionOS device** (cannot test on simulator)

### Success Criteria
- ✅ Immersive space opens without crashes
- ✅ Plane detection works reliably
- ✅ Model anchors at correct location
- ✅ Scale is proportional and realistic
- ✅ Can exit immersive mode smoothly

### Questions for Review
1. **Priority**: Is AR mode required for MVP, or can it be deferred?
2. **Scale Configuration**: Should users set scale manually, or auto-detect from model metadata?
3. **Hardware Access**: Do you have access to Vision Pro for testing?

**Recommendation**: Skip Part 4 for initial MVP, focus on window-based viewing.

---

## Part 5: Supabase Backend Setup
**Duration Estimate**: 2-3 days
**Dependencies**: None (can be done in parallel)
**Risk Level**: Low (well-documented service)

### Goals
- Set up cloud infrastructure for data storage
- Configure authentication and access control
- Prepare for multi-user collaboration

### Deliverables

#### 5.1 Create Supabase Project
- [ ] Sign up at supabase.com
- [ ] Create new project (name: `ortio-prod`)
- [ ] Note API URL and anon key
- [ ] Create test project (name: `ortio-test`) for development

#### 5.2 Database Schema
**New File**: `/database/schema.sql`

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    profile_image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Models table (metadata only, files in Storage)
CREATE TABLE models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Annotations table
CREATE TABLE annotations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID REFERENCES models(id) ON DELETE CASCADE,
    author_id UUID REFERENCES users(id) ON DELETE CASCADE,
    position_x REAL NOT NULL,
    position_y REAL NOT NULL,
    position_z REAL NOT NULL,
    rotation_x REAL NOT NULL,
    rotation_y REAL NOT NULL,
    rotation_z REAL NOT NULL,
    rotation_w REAL NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Model sharing
CREATE TABLE model_shares (
    model_id UUID REFERENCES models(id) ON DELETE CASCADE,
    shared_with_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    permission TEXT DEFAULT 'view' CHECK (permission IN ('view', 'annotate')),
    PRIMARY KEY (model_id, shared_with_user_id)
);

-- Indexes for performance
CREATE INDEX idx_models_owner ON models(owner_id);
CREATE INDEX idx_annotations_model ON annotations(model_id);
CREATE INDEX idx_annotations_author ON annotations(author_id);
CREATE INDEX idx_model_shares_user ON model_shares(shared_with_user_id);
```

#### 5.3 Row-Level Security (RLS)
**New File**: `/database/rls_policies.sql`

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE models ENABLE ROW LEVEL SECURITY;
ALTER TABLE annotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE model_shares ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "users_read_own" ON users FOR SELECT
    USING (id = auth.uid());

-- Users can update their own profile
CREATE POLICY "users_update_own" ON users FOR UPDATE
    USING (id = auth.uid());

-- Users can view models they own
CREATE POLICY "models_read_own" ON models FOR SELECT
    USING (owner_id = auth.uid());

-- Users can view models shared with them
CREATE POLICY "models_read_shared" ON models FOR SELECT
    USING (id IN (
        SELECT model_id FROM model_shares WHERE shared_with_user_id = auth.uid()
    ));

-- Users can insert their own models
CREATE POLICY "models_insert_own" ON models FOR INSERT
    WITH CHECK (owner_id = auth.uid());

-- Users can update their own models
CREATE POLICY "models_update_own" ON models FOR UPDATE
    USING (owner_id = auth.uid());

-- Users can delete their own models
CREATE POLICY "models_delete_own" ON models FOR DELETE
    USING (owner_id = auth.uid());

-- Annotations: users can view annotations on accessible models
CREATE POLICY "annotations_read" ON annotations FOR SELECT
    USING (model_id IN (
        SELECT id FROM models WHERE owner_id = auth.uid()
        UNION
        SELECT model_id FROM model_shares WHERE shared_with_user_id = auth.uid()
    ));

-- Users can insert annotations on accessible models (if permission allows)
CREATE POLICY "annotations_insert" ON annotations FOR INSERT
    WITH CHECK (
        author_id = auth.uid() AND
        model_id IN (
            SELECT id FROM models WHERE owner_id = auth.uid()
            UNION
            SELECT model_id FROM model_shares
            WHERE shared_with_user_id = auth.uid() AND permission = 'annotate'
        )
    );

-- Users can update their own annotations
CREATE POLICY "annotations_update_own" ON annotations FOR UPDATE
    USING (author_id = auth.uid());

-- Users can delete their own annotations
CREATE POLICY "annotations_delete_own" ON annotations FOR DELETE
    USING (author_id = auth.uid());
```

#### 5.4 Configure Storage Bucket
- [ ] Create storage bucket named `models`
- [ ] Set max file size to 50MB
- [ ] Configure MIME type restrictions (allow `.usdz`, `.zip`)
- [ ] Enable RLS on storage bucket

#### 5.5 Enable Authentication
- [ ] Enable Email/Password authentication
- [ ] Configure email templates (welcome, password reset)
- [ ] Set up email provider (default SMTP or custom)

#### 5.6 Create Test Accounts
- [ ] Create `alice@test.com` account
- [ ] Create `bob@test.com` account
- [ ] Insert test user records in database

#### 5.7 Secure Credentials
**New File**: `/Configuration/Secrets.xcconfig`

```
// DO NOT COMMIT THIS FILE
SUPABASE_URL = https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY = YOUR_ANON_KEY
```

**Update**: `/.gitignore`
```
Configuration/Secrets.xcconfig
```

### Success Criteria
- ✅ Database schema deployed successfully
- ✅ RLS policies prevent unauthorized access (tested manually)
- ✅ Storage bucket accepts USDZ uploads
- ✅ Email authentication works for test accounts
- ✅ Credentials stored securely (not in git)

### Questions for Review
1. **Supabase Plan**: Free tier (500MB storage) sufficient, or need paid plan?
2. **Authentication**: Email/password only, or add OAuth (Google, Apple)?
3. **File Size Limit**: 50MB appropriate for USDZ models, or increase?
4. **Sharing Model**: Current design allows email-based sharing. Add invite links?

---

## Part 6: Networking Layer
**Duration Estimate**: 3-4 days
**Dependencies**: Part 1, Part 5
**Risk Level**: Medium

### Goals
- Create testable, protocol-based networking layer
- Integrate Supabase Swift SDK
- Enable dependency injection for testing

### Deliverables

#### 6.1 Add Supabase Swift SDK
- [ ] Add package dependency: `https://github.com/supabase/supabase-swift`
- [ ] Link to `GuidedCaptureShared` framework
- [ ] Import in networking files

#### 6.2 NetworkProtocol Definition
**New File**: `/GuidedCaptureShared/Networking/NetworkProtocol.swift`

```swift
import Foundation

protocol NetworkProtocol {
    // Authentication
    func signUp(email: String, password: String) async throws -> UserRecord
    func signIn(email: String, password: String) async throws -> UserRecord
    func signOut() async throws
    func getCurrentUser() async throws -> UserRecord?

    // Model operations
    func uploadModel(localURL: URL, modelId: UUID, userId: UUID) async throws -> String
    func downloadModel(modelId: UUID, toLocalURL: URL) async throws
    func fetchModels(for userId: UUID) async throws -> [ModelRecord]
    func deleteModel(modelId: UUID) async throws

    // Annotation operations
    func uploadAnnotation(_ annotation: AnnotationRecord) async throws
    func fetchAnnotations(for modelId: UUID) async throws -> [AnnotationRecord]
    func updateAnnotation(_ annotation: AnnotationRecord) async throws
    func deleteAnnotation(annotationId: UUID) async throws

    // Sharing operations
    func shareModel(modelId: UUID, withUserEmail: String, permission: SharePermission) async throws
    func fetchSharedModels(for userId: UUID) async throws -> [ModelRecord]
}

enum SharePermission: String, Codable {
    case view
    case annotate
}
```

#### 6.3 Data Transfer Objects (DTOs)
**New Files**:

`/GuidedCaptureShared/SupabaseModels/UserRecord.swift`
```swift
import Foundation

struct UserRecord: Codable, Identifiable {
    let id: UUID
    let username: String
    let name: String
    let profileImageUrl: String?
    let createdAt: Date
}
```

`/GuidedCaptureShared/SupabaseModels/ModelRecord.swift`
```swift
import Foundation

struct ModelRecord: Codable, Identifiable {
    let id: UUID
    let ownerId: UUID
    let name: String
    let fileUrl: String
    let fileSize: Int64
    let createdAt: Date
    let updatedAt: Date
}
```

`/GuidedCaptureShared/SupabaseModels/AnnotationRecord.swift`
```swift
import Foundation

struct AnnotationRecord: Codable, Identifiable {
    let id: UUID
    let modelId: UUID
    let authorId: UUID
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let rotationX: Float
    let rotationY: Float
    let rotationZ: Float
    let rotationW: Float
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
}
```

#### 6.4 CloudStorageService Implementation
**New File**: `/GuidedCaptureShared/Networking/CloudStorageService.swift`

```swift
import Foundation
import Supabase

final class CloudStorageService: NetworkProtocol {
    private let supabaseClient: SupabaseClient

    init(url: String, anonKey: String) {
        self.supabaseClient = SupabaseClient(
            supabaseURL: URL(string: url)!,
            supabaseKey: anonKey
        )
    }

    // Implement all NetworkProtocol methods using Supabase SDK
}
```

#### 6.5 Mock Network Service
**New File**: `/GuidedCaptureTests/mocks/MockNetworkService.swift`

```swift
import Foundation
@testable import GuidedCaptureShared

final class MockNetworkService: NetworkProtocol {
    // Call tracking
    var signUpCallCount = 0
    var uploadModelCallCount = 0
    var fetchAnnotationsCallCount = 0

    // Stubs
    var signUpStub: ((String, String) async throws -> UserRecord)?
    var uploadModelStub: ((URL, UUID, UUID) async throws -> String)?
    var fetchAnnotationsStub: ((UUID) async throws -> [AnnotationRecord])?

    // Implement all protocol methods with tracking and stubs
}
```

#### 6.6 Error Handling
**New File**: `/GuidedCaptureShared/Networking/NetworkError.swift`

```swift
import Foundation

enum NetworkError: LocalizedError {
    case authenticationFailed
    case unauthorized
    case networkUnavailable
    case fileNotFound
    case uploadFailed(String)
    case downloadFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .authenticationFailed: "Authentication failed"
        case .unauthorized: "Unauthorized access"
        case .networkUnavailable: "Network unavailable"
        case .fileNotFound: "File not found"
        case .uploadFailed(let msg): "Upload failed: \(msg)"
        case .downloadFailed(let msg): "Download failed: \(msg)"
        case .invalidResponse: "Invalid server response"
        }
    }
}
```

#### 6.7 Write Tests
**New File**: `/GuidedCaptureTests/CloudStorageServiceTests.swift`
- Test authentication flow (sign up, sign in, sign out)
- Test model upload/download
- Test annotation CRUD
- Test error handling

### Success Criteria
- ✅ `NetworkProtocol` defines all required operations
- ✅ `CloudStorageService` compiles without errors
- ✅ `MockNetworkService` tracks calls correctly
- ✅ Unit tests pass for error handling
- ✅ Can authenticate with Supabase test account

### Questions for Review
1. **Authentication Storage**: Store session token in Keychain or UserDefaults?
2. **Retry Logic**: Should network service auto-retry failed requests?
3. **Progress Tracking**: Include upload/download progress callbacks in protocol?

---

## Part 7: iOS Model Upload
**Duration Estimate**: 2-3 days
**Dependencies**: Part 6
**Risk Level**: Low

### Goals
- Enable uploading scanned models to cloud
- Show upload progress
- Handle errors gracefully

### Deliverables

#### 7.1 Update ModelsViewModel
**File**: `/ModelsViewModel.swift`

- Add `NetworkProtocol` dependency injection
- Add `@Published var uploadProgress: Double`
- Add `@Published var uploadStatus: UploadStatus`
- Implement `uploadModel(_ model: Models) async`
- Handle background URL sessions

#### 7.2 Update ModelsView UI
**File**: `/ModelsView.swift`

- Add "Upload to Cloud" button per model
- Show progress indicator during upload
- Display success/error messages
- Add cloud sync status badge (uploaded vs local-only)

#### 7.3 Background Upload
**New File**: `/GuidedCapture/Utilities/BackgroundUploadManager.swift`

- Configure `URLSessionConfiguration.background`
- Handle upload tasks surviving app backgrounding
- Persist upload state to UserDefaults

#### 7.4 Save Cloud URL
- After successful upload, save `fileUrl` to local `Models` record
- Mark model as "synced to cloud"

#### 7.5 Write Tests
**New File**: `/GuidedCaptureTests/ModelUploadTests.swift`
- Test upload flow with `MockNetworkService`
- Test progress tracking
- Test error handling
- Test background upload restoration

### Success Criteria
- ✅ "Upload" button visible on local models
- ✅ Upload progress shows accurately
- ✅ Successful upload confirmed with message
- ✅ Uploaded models show cloud badge
- ✅ Upload survives app backgrounding

### Questions for Review
1. **Auto-Upload**: Should models upload automatically after capture, or manual trigger?
2. **WiFi Only**: Restrict uploads to WiFi, or allow cellular?
3. **Upload Queue**: Support uploading multiple models simultaneously?

---

## Part 8: visionOS Model Download & Browser
**Duration Estimate**: 2-3 days
**Dependencies**: Part 6, Part 7
**Risk Level**: Low

### Goals
- Browse cloud models in visionOS
- Download models for local viewing
- Implement cache management

### Deliverables

#### 8.1 CloudBrowserViewModel
**New File**: `/GuidedCaptureVision/ViewModels/CloudBrowserViewModel.swift`

```swift
import SwiftUI
import GuidedCaptureShared

@Observable
final class CloudBrowserViewModel {
    var cloudModels: [ModelRecord] = []
    var downloadProgress: [UUID: Double] = [:]
    var isLoading = false

    @ObservationIgnored private let networkService: NetworkProtocol
    @ObservationIgnored private let fileManager: FileManagerProtocol

    init(networkService: NetworkProtocol, fileManager: FileManagerProtocol = FileManager.default) {
        self.networkService = networkService
        self.fileManager = fileManager
    }

    @MainActor
    func fetchCloudModels() async {
        // Fetch models from network service
    }

    @MainActor
    func downloadModel(_ model: ModelRecord) async throws {
        // Download to cache directory
    }
}
```

#### 8.2 CloudBrowserView
**New File**: `/GuidedCaptureVision/Views/CloudBrowserView.swift`

- Grid layout showing cloud models
- Download button per model
- Progress indicator during download
- "Open" action to view downloaded model
- Filter: "My Models" vs "Shared with Me"

#### 8.3 Cache Management
**New File**: `/GuidedCaptureShared/Utilities/ModelCacheManager.swift`

- Cache location: `Library/Caches/Models/<modelId>.usdz`
- Track cache size
- Implement LRU eviction (delete oldest when >500MB)
- Provide cache clearing utility

#### 8.4 Integrate with ModelViewer
- Update `ModelViewerViewModel` to accept both local and cached models
- Handle missing cache files gracefully

#### 8.5 Write Tests
**New File**: `/GuidedCaptureTests/CloudBrowserViewModelTests.swift`
- Test fetching cloud models
- Test download flow
- Test cache eviction
- Test error handling

### Success Criteria
- ✅ Cloud models display in grid
- ✅ Download progress shows accurately
- ✅ Downloaded models open in 3D viewer
- ✅ Cache eviction works when limit exceeded
- ✅ Shared models show in separate section

### Questions for Review
1. **Cache Size**: 500MB limit appropriate, or make configurable?
2. **Download Strategy**: Download full model upfront, or stream?
3. **Offline Mode**: Cache models for offline viewing, or require network?

---

## Part 9: Annotation UI (visionOS)
**Duration Estimate**: 4-5 days
**Dependencies**: Part 3, Part 6
**Risk Level**: High (RealityKit raycasting complexity)

### Goals
- Enable creating annotations by tapping 3D model
- Display annotation markers in RealityKit scene
- Implement annotation list and navigation

### Deliverables

#### 9.1 AnnotationViewModel
**New File**: `/GuidedCaptureVision/ViewModels/AnnotationViewModel.swift`

```swift
import SwiftUI
import SwiftData
import GuidedCaptureShared

@Observable
final class AnnotationViewModel {
    var annotations: [Annotation] = []
    var selectedAnnotation: Annotation?

    @ObservationIgnored private let networkService: NetworkProtocol
    @ObservationIgnored private var modelContext: ModelContext

    init(modelContext: ModelContext, networkService: NetworkProtocol) {
        self.modelContext = modelContext
        self.networkService = networkService
    }

    @MainActor
    func createAnnotation(modelId: UUID, position: SIMD3<Float>, rotation: simd_quatf, title: String, content: String) {
        // Save to SwiftData, queue for upload
    }

    @MainActor
    func fetchAnnotations(for modelId: UUID) async {
        // Fetch from local SwiftData and merge with cloud
    }

    @MainActor
    func deleteAnnotation(_ annotation: Annotation) {
        // Delete locally and from cloud
    }
}
```

#### 9.2 Raycasting & Hit Detection
**New File**: `/GuidedCaptureVision/RealityKit/RaycastHandler.swift`

- Implement tap gesture on RealityKit scene
- Perform raycast to detect model surface hit
- Convert world-space hit point to model-relative coordinates
- Return position and surface normal (for rotation)

#### 9.3 Annotation Marker Entity
**New File**: `/GuidedCaptureVision/RealityKit/AnnotationMarkerEntity.swift`

```swift
import RealityKit

final class AnnotationMarkerEntity: Entity {
    let annotation: Annotation

    init(annotation: Annotation) {
        self.annotation = annotation
        super.init()

        // Create sphere geometry
        let mesh = MeshResource.generateSphere(radius: 0.02)
        let material = SimpleMaterial(color: .blue, isMetallic: false)
        let modelComponent = ModelComponent(mesh: mesh, materials: [material])
        self.components[ModelComponent.self] = modelComponent

        // Create text billboard
        // ...
    }

    required init() {
        fatalError("Use init(annotation:)")
    }
}
```

#### 9.4 Annotation Input Modal
**New File**: `/GuidedCaptureVision/Views/AnnotationInputView.swift`

- SwiftUI sheet/modal view
- Text field for title (max 50 chars)
- TextEditor for content (max 500 chars)
- Save / Cancel buttons
- Show character count

#### 9.5 Annotation List View
**New File**: `/GuidedCaptureVision/Views/AnnotationListView.swift`

- List all annotations for current model
- Show title, author, date
- Tap to "jump to" annotation (camera animation)
- Swipe to delete (only own annotations)

#### 9.6 Toggle Visibility
- Add toggle button to `ModelViewerView` (eye icon)
- Hide/show all annotation markers
- Fade-in/fade-out animation
- Persist visibility state in UserDefaults

#### 9.7 Write Tests
**New File**: `/GuidedCaptureTests/AnnotationViewModelTests.swift`
- Test annotation creation
- Test coordinate conversion
- Test SwiftData persistence
- Test deletion

### Success Criteria
- ✅ Tap model → raycast hit detected
- ✅ Annotation modal appears with input fields
- ✅ Annotation marker visible at correct position
- ✅ Annotation persists after app restart
- ✅ Marker stays anchored when model transformed
- ✅ Can toggle annotation visibility
- ✅ Annotation list shows all annotations

### Questions for Review
1. **Marker Design**: Sphere + billboard text, or custom 3D pin design?
2. **Color Coding**: Color markers by author, or all same color?
3. **Edit Flow**: Long-press marker to edit, or edit from list only?
4. **Max Annotations**: Limit annotations per model (e.g., 100)?

---

## Part 10: Annotation Cloud Sync
**Duration Estimate**: 3-4 days
**Dependencies**: Part 9
**Risk Level**: Medium

### Goals
- Sync annotations to Supabase
- Implement conflict resolution
- Support offline annotation creation

### Deliverables

#### 10.1 SyncManager
**New File**: `/GuidedCaptureShared/Networking/SyncManager.swift`

```swift
import Foundation
import SwiftData

final class SyncManager {
    private let networkService: NetworkProtocol
    private let modelContext: ModelContext

    init(networkService: NetworkProtocol, modelContext: ModelContext) {
        self.networkService = networkService
        self.modelContext = modelContext
    }

    func syncAnnotations(for modelId: UUID) async throws {
        // 1. Fetch cloud annotations
        // 2. Fetch local pending annotations
        // 3. Upload pending annotations
        // 4. Merge cloud annotations (conflict resolution)
        // 5. Update sync status
    }

    private func resolveConflicts(local: Annotation, remote: AnnotationRecord) -> Annotation {
        // Last-write-wins based on updatedAt
    }
}
```

#### 10.2 Background Upload Queue
**New File**: `/GuidedCaptureShared/Utilities/UploadQueue.swift`

- Queue pending annotations for upload
- Retry failed uploads with exponential backoff
- Monitor network reachability
- Auto-sync when network restored

#### 10.3 Update AnnotationViewModel
- Call `SyncManager.syncAnnotations()` on app launch
- Call after creating/updating annotations
- Handle sync errors gracefully

#### 10.4 Sync Status UI
- Show sync status per annotation (pending, synced, failed)
- Display sync indicator in annotation list
- Allow manual retry for failed syncs

#### 10.5 Write Tests
**New File**: `/GuidedCaptureTests/SyncManagerTests.swift`
- Test upload queue
- Test conflict resolution (last-write-wins)
- Test offline queue persistence
- Test retry logic

### Success Criteria
- ✅ Annotations upload automatically when online
- ✅ Offline annotations queue and sync when online
- ✅ Conflict resolution works correctly
- ✅ Sync status displayed accurately
- ✅ Failed syncs retry with backoff

### Questions for Review
1. **Sync Frequency**: Sync on every change, or batch sync every N minutes?
2. **Conflict UI**: Show conflict resolution to user, or auto-resolve silently?
3. **Offline Queue**: Persist queue to disk, or in-memory only?

---

## Part 11: Model Sharing
**Duration Estimate**: 2-3 days
**Dependencies**: Part 7, Part 8
**Risk Level**: Low

### Goals
- Enable sharing models with other users
- Implement permission-based access
- Display shared models in visionOS

### Deliverables

#### 11.1 Share Sheet (iOS)
**New File**: `/GuidedCapture/Views/ShareModelView.swift`

- Modal sheet with text field for email
- Picker for permission (view / annotate)
- Send button triggers `NetworkProtocol.shareModel()`
- Show confirmation or error

#### 11.2 Update ModelsView
**File**: `/ModelsView.swift`
- Add "Share" button to model actions
- Present `ShareModelView` sheet

#### 11.3 Shared Models Section (visionOS)
**File**: `/GuidedCaptureVision/Views/CloudBrowserView.swift`
- Add "Shared with Me" tab/section
- Fetch shared models via `NetworkProtocol.fetchSharedModels()`
- Display with different badge/icon

#### 11.4 Permission Enforcement
- Respect `view` vs `annotate` permissions
- Disable annotation creation for view-only models
- Show permission badge in UI

#### 11.5 Write Tests
**New File**: `/GuidedCaptureTests/ModelSharingTests.swift`
- Test share flow
- Test permission enforcement
- Test fetching shared models

### Success Criteria
- ✅ Can share model by email
- ✅ Shared user sees model in "Shared with Me"
- ✅ View-only permission prevents annotations
- ✅ Annotate permission allows annotations
- ✅ RLS policies enforce access control

### Questions for Review
1. **Share by Link**: Add shareable links, or email-only?
2. **Revoke Access**: Add UI to revoke sharing?
3. **Notification**: Email notification when model shared with user?

---

## Part 12: Testing & Polish
**Duration Estimate**: 3-4 days
**Dependencies**: All previous parts
**Risk Level**: Low

### Goals
- Achieve 80%+ test coverage
- Write integration tests
- Optimize performance
- Fix bugs

### Deliverables

#### 12.1 Unit Test Coverage
- [ ] All ViewModels tested (MVVM pattern)
- [ ] All network operations tested with mocks
- [ ] SwiftData models tested with in-memory containers
- [ ] Utility classes tested (cache manager, sync manager)
- [ ] Verify 80%+ coverage with Xcode coverage report

#### 12.2 Integration Tests
**New Directory**: `/GuidedCaptureTests/IntegrationTests/`

**New Files**:
- `FullWorkflowTests.swift` - iOS scan → upload → visionOS download
- `AnnotationSyncTests.swift` - Multi-device annotation sync
- `ModelSharingTests.swift` - Share and access flow

#### 12.3 Performance Optimization
- [ ] Profile RealityKit rendering with Instruments
- [ ] Optimize annotation marker rendering (spatial culling if >100 annotations)
- [ ] Add indexes to SwiftData queries
- [ ] Compress textures in USDZ files before upload
- [ ] Implement pagination for annotation list (50 per page)

#### 12.4 Error Handling Audit
- [ ] Review all error messages
- [ ] Add user-friendly error descriptions
- [ ] Implement error recovery (retry buttons)
- [ ] Log errors for debugging

#### 12.5 UI/UX Polish
- [ ] Consistent styling across iOS and visionOS
- [ ] Loading states for async operations
- [ ] Empty states ("No models yet")
- [ ] Accessibility (VoiceOver labels)
- [ ] Dark mode support

### Success Criteria
- ✅ All tests pass
- ✅ 80%+ code coverage
- ✅ Integration tests pass
- ✅ No memory leaks (tested with Instruments)
- ✅ RealityKit renders at 60fps
- ✅ UI feels polished and responsive

### Questions for Review
1. **Beta Testing**: Plan for external beta testing?
2. **Analytics**: Add analytics (e.g., Mixpanel) to track usage?
3. **Crash Reporting**: Add crash reporting (e.g., Sentry)?

---

## Implementation Sequence

### Recommended Order

**Phase 1: Foundation (Weeks 1-2)**
- Part 1: Shared Framework
- Part 5: Supabase Backend (parallel)
- Part 2: visionOS Scaffold

**Phase 2: Core Features (Weeks 3-4)**
- Part 3: RealityKit Viewer
- Part 6: Networking Layer
- Part 7: iOS Upload

**Phase 3: Collaboration (Weeks 5-6)**
- Part 8: visionOS Browser
- Part 9: Annotation UI
- Part 10: Annotation Sync

**Phase 4: Sharing & Polish (Week 7)**
- Part 11: Model Sharing
- Part 12: Testing & Polish

**Optional**:
- Part 4: AR Immersive Mode (defer to post-MVP)

### Total Timeline: 7 weeks

---

## Key Decisions to Review Before Starting

### Critical Decisions
1. **Cloud Provider**: Confirm Supabase, or evaluate alternatives?
2. **AR Mode**: Include in MVP (Part 4), or defer?
3. **Authentication**: Email/password only, or add OAuth?
4. **Sync Strategy**: Confirm last-write-wins, or implement CRDT?

### Resource Questions
1. **visionOS Hardware**: Do you have Vision Pro for testing?
2. **Supabase Plan**: Free tier sufficient, or need paid plan?
3. **Time Allocation**: 7-week timeline realistic for your schedule?

### Technical Risks
1. **RealityKit Complexity**: Raycasting and coordinate conversion may need iteration
2. **Supabase RLS**: Policies must be thoroughly tested for security
3. **Sync Conflicts**: Edge cases in conflict resolution may emerge

---

## Next Steps

### Option A: Sequential Implementation
1. Review and approve each part
2. Implement Part 1
3. Review deliverables
4. Proceed to Part 2
5. Repeat

### Option B: Parallel Workstreams
1. Start Part 1 (Framework) + Part 5 (Supabase) simultaneously
2. Once Part 1 done → Part 2 (visionOS Scaffold)
3. Once Part 5 done → Part 6 (Networking Layer)
4. Converge at Part 9 (Annotation UI)

### Option C: MVP-First Approach
1. Implement minimal path: Parts 1, 2, 3, 5, 6, 7, 8 only
2. Skip annotations initially (defer Parts 9, 10, 11)
3. Get iOS→visionOS model viewing working end-to-end
4. Add annotation system in Phase 2

**Recommendation**: Option C (MVP-First) for fastest time-to-value.

---

## Questions for You

Before I start implementing, please review and answer:

1. **Which implementation approach do you prefer?** (Sequential / Parallel / MVP-First)
2. **Which parts are highest priority?** (Rank 1-12)
3. **Which parts can be skipped for MVP?** (e.g., Part 4 AR Mode)
4. **Do you have visionOS hardware for testing?** (Yes / No)
5. **Preferred timeline?** (7 weeks realistic? Shorter? Longer?)
6. **Any concerns or questions about the architecture?**

Please provide your feedback, and I'll proceed with implementation!
