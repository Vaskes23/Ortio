# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ortio is an iOS app for 3D object capture and model management. It is built with Swift/SwiftUI and based on Apple's GuidedCapture sample project. Requires a physical device with LiDAR Scanner, A14 Bionic+, and iOS 17+.

## Build & Test Commands

```bash
# Open in Xcode
open GuidedCapture.xcodeproj

# Build (command line)
xcodebuild -project GuidedCapture.xcodeproj -scheme GuidedCapture -configuration Debug -destination 'platform=iOS,name=<DEVICE_NAME>'

# Run all tests
xcodebuild test -project GuidedCapture.xcodeproj -scheme GuidedCapture -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test class
xcodebuild test -project GuidedCapture.xcodeproj -scheme GuidedCapture -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:GuidedCaptureTests/ImportViewModelTests

# Run a single test method
xcodebuild test -project GuidedCapture.xcodeproj -scheme GuidedCapture -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:GuidedCaptureTests/ImportViewModelTests/testCreateFolderName
```

## Architecture

**MVVM with Dependency Injection:**
- **Views** (`*View.swift`): SwiftUI views using `@State`, `@Query`, `@Environment`
- **ViewModels** (`*ViewModel.swift`): `ObservableObject` classes with `@Published` properties; accept `FileManagerProtocol` for testability
- **Models** (`*Model.swift`): Data models; persistent models use SwiftData `@Model` macro

**Project Structure (feature-based):**
```
GuidedCapture/                          # Main iOS app target
├── App/                                # App entry point & root navigation
│   ├── GuidedCaptureSampleApp.swift    # @main entry point
│   └── ContentView.swift              # Main TabView (Models, Import tabs)
├── Features/
│   ├── Capture/                        # 3D object capture
│   │   ├── Views/                      # CapturePrimaryView, CaptureOverlayView, etc.
│   │   ├── ViewModels/                 # AppDataModel + extensions
│   │   ├── Models/                     # CaptureFolderManager, ShotFileInfo, FileManagerProtocol, PathConstants
│   │   └── Utilities/                  # FeedbackMessages, TimedMessageList
│   ├── Onboarding/                     # Onboarding tutorial flow
│   │   ├── Views/                      # OnboardingView, OnboardingTutorialView, etc.
│   │   └── ViewModels/                 # OnboardingStateMachine
│   ├── Models/                         # "Models" tab (browse 3D models)
│   │   ├── Views/                      # ModelsView
│   │   ├── ViewModels/                 # ModelsViewModel
│   │   └── Models/                     # ModelsModel, Models (SwiftData)
│   ├── Import/                         # "Import" tab (import 3D files)
│   │   ├── Views/                      # ImportView
│   │   ├── ViewModels/                 # ImportViewModel
│   │   └── Models/                     # ImportModel
│   └── Settings/                       # Settings & profile
│       ├── Views/                      # SettingsView, EditProfileView
│       ├── ViewModels/                 # SettingsViewModel
│       └── Models/                     # User (SwiftData), Theme
├── SharedUI/                           # Reusable UI (PlayerView, ProgressBarView, TutorialVideoView)
├── Resources/                          # MP4 tutorial videos
└── Assets.xcassets/

GuidedCaptureShared/                    # Shared models, networking, utilities
├── Models/                             # Annotation, Models, Theme, User
├── Networking/                         # CloudStorageService, NetworkProtocol
├── SupabaseModels/                     # AnnotationRecord, ModelRecord, UserRecord
└── Utilities/                          # FileManagerProtocol, PathConstants

GuidedCaptureTests/                     # Unit tests
├── Features/{Import,Models,Settings}/  # Feature-specific tests
├── Shared/                             # Shared model tests
├── Core/                               # Core/binding tests
└── Mocks/                              # FileManagerMocks, MockNetworkService
```

**Data Persistence:** SwiftData with in-memory containers for tests. Models: `Models`, `User`, `CreatedModels`.

**File Storage:** Documents folder structure: `~/Documents/Scans/<timestamp>/{Images, Snapshots, Models}`

**Project Generation:** Uses XcodeGen (`project.yml`). Run `xcodegen generate` after adding/moving files.

## Code Conventions

- Views suffixed with `View`, ViewModels with `ViewModel`, data models with `Model`
- Large views/classes split into extensions in separate files (e.g., `CaptureOverlayView+Buttons.swift`, `*+LocalizedString.swift`)
- Protocol-based design for testability (`FileManagerProtocol`)
- ViewModels default to `FileManager.default` in production, accept mock in tests

## Testing

Tests are in `GuidedCaptureTests/`, organized by feature to mirror the main target structure. Uses XCTest with Arrange-Act-Assert pattern.

- `Mocks/FileManagerMocks.swift` provides `MockFileManager` with call tracking and stubbing
- SwiftData tests use `ModelConfiguration(isStoredInMemoryOnly: true)`
- Tests inject `MockFileManager` into ViewModels for isolation
- Feature tests are in `Features/{Import,Models,Settings}/`
- Shared model tests are in `Shared/`

## XcodeBuildMCP (Optional)

XcodeBuildMCP is configured in `.mcp.json` for enhanced Xcode integration. It provides 100 tools for building, testing, simulator management, UI automation, and debugging.

**When to use MCP tools (preferred for):**
- Test result parsing (structured pass/fail counts)
- Build error/warning reporting (pre-parsed with file:line)
- Multi-step workflows (build + install + launch)
- UI automation via axe
- Debugging via DAP/lldb

**When to use bash (preferred for):**
- Simple builds (`xcodebuild build`)
- Clean builds
- Quick one-off commands where raw output is fine

**Simulator destination:** Use device ID for reliability:
```
-destination 'platform=iOS Simulator,id=A9355665-734F-40CF-9798-EC628DC5F976'
```

**Note:** Telemetry is disabled via `XCODEBUILDMCP_SENTRY_DISABLED=true` in `.mcp.json`.
