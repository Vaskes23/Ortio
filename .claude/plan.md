# Ortio Project Restructuring Plan

## Problem Summary

The Ortio codebase has grown organically and now suffers from:

1. **14 Swift files scattered in the project root** — feature code (Settings, Import, Models) lives outside any folder
2. **5 fully duplicate files** between root and `GuidedCaptureShared/` (FileManagerProtocol, Models, User, Theme, PathConstants)
3. **Flat `GuidedCapture/` folder** with 28 files mixing capture, onboarding, UI utilities, and app-level code
4. **No feature-based grouping** — Views, ViewModels, and Models for the same feature are not co-located
5. **Tests are flat** — all 13 test files in one directory with no sub-grouping

---

## Proposed Directory Structure

```
Ortio/
├── GuidedCapture/                          # Main iOS app target
│   ├── App/                                # App entry point & root navigation
│   │   ├── GuidedCaptureSampleApp.swift
│   │   └── ContentView.swift
│   │
│   ├── Features/
│   │   ├── Capture/                        # 3D object capture feature
│   │   │   ├── Views/
│   │   │   │   ├── CapturePrimaryView.swift
│   │   │   │   ├── CaptureOverlayView.swift
│   │   │   │   ├── CaptureOverlayView+Buttons.swift
│   │   │   │   ├── CaptureOverlayView+LocalizedString.swift
│   │   │   │   ├── LoadGuidedCaptureView.swift
│   │   │   │   ├── ModelView.swift
│   │   │   │   ├── FeedbackView.swift
│   │   │   │   ├── HelpPageView.swift
│   │   │   │   └── ReconstructionPrimaryView.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── AppDataModel.swift      (+ extensions below)
│   │   │   │   └── AppDataModel+Orbit.swift
│   │   │   │   └── AppDataModel+State.swift
│   │   │   ├── Models/
│   │   │   │   ├── ShotFileInfo.swift
│   │   │   │   └── CaptureFolderManager.swift
│   │   │   └── Utilities/
│   │   │       ├── FeedbackMessages.swift
│   │   │       ├── TimedMessageList.swift
│   │   │       └── UntilProcessingCompleteFilter.swift
│   │   │
│   │   ├── Onboarding/                     # Onboarding/tutorial feature
│   │   │   ├── Views/
│   │   │   │   ├── OnboardingView.swift
│   │   │   │   ├── OnboardingTutorialView.swift
│   │   │   │   ├── OnboardingTutorialView+LocalizedString.swift
│   │   │   │   ├── OnboardingButtonView.swift
│   │   │   │   └── OnboardingButtonView+LocalizedString.swift
│   │   │   └── ViewModels/
│   │   │       └── OnboardingStateMachine.swift
│   │   │
│   │   ├── Models/                         # "Models" tab (browse 3D models)
│   │   │   ├── Views/
│   │   │   │   └── ModelsView.swift        ← from root
│   │   │   ├── ViewModels/
│   │   │   │   └── ModelsViewModel.swift   ← from root
│   │   │   └── Models/
│   │   │       └── ModelsModel.swift       ← from root
│   │   │
│   │   ├── Import/                         # "Import" tab (import 3D files)
│   │   │   ├── Views/
│   │   │   │   └── ImportView.swift        ← from root
│   │   │   ├── ViewModels/
│   │   │   │   └── ImportViewModel.swift   ← from root
│   │   │   └── Models/
│   │   │       └── ImportModel.swift       ← from root
│   │   │
│   │   └── Settings/                       # Settings feature
│   │       ├── Views/
│   │       │   ├── SettingsView.swift       ← from root
│   │       │   └── EditProfileView.swift    ← from root
│   │       └── ViewModels/
│   │           └── SettingsViewModel.swift   ← from root
│   │
│   ├── SharedUI/                           # Reusable UI components
│   │   ├── PlayerView.swift
│   │   ├── ProgressBarView.swift
│   │   └── TutorialVideoView.swift
│   │
│   ├── Resources/                          # (already exists — MP4 videos)
│   ├── Assets.xcassets/                    # (already exists)
│   ├── Preview Content/                    # (already exists)
│   └── Info.plist
│
├── GuidedCaptureShared/                    # Shared framework (canonical location for shared code)
│   ├── Models/
│   │   ├── Annotation.swift
│   │   ├── Models.swift                    ← KEEP (delete root duplicate)
│   │   ├── Theme.swift                     ← KEEP (delete root duplicate)
│   │   └── User.swift                      ← KEEP (delete root duplicate)
│   ├── Networking/
│   │   ├── CloudStorageService.swift
│   │   └── NetworkProtocol.swift
│   ├── SupabaseModels/
│   │   ├── AnnotationRecord.swift
│   │   ├── ModelRecord.swift
│   │   └── UserRecord.swift
│   └── Utilities/
│       ├── FileManagerProtocol.swift       ← KEEP (delete root duplicate)
│       └── PathConstants.swift             ← KEEP (delete root duplicate)
│
├── GuidedCaptureVision/                    # visionOS target (unchanged)
│   ├── GuidedCaptureVisionApp.swift
│   ├── ViewModels/
│   │   └── ModelViewerViewModel.swift
│   └── Views/
│       ├── ContentView.swift
│       ├── ModelBrowserView.swift
│       ├── ModelViewerView.swift
│       └── SettingsView.swift
│
├── GuidedCaptureWidgets/                   # Widgets target (unchanged)
│   └── (4 files, unchanged)
│
├── GuidedCaptureTests/                     # Tests (restructured)
│   ├── Features/
│   │   ├── Import/
│   │   │   ├── ImportTests.swift
│   │   │   └── ImportViewModelTests.swift
│   │   ├── Models/
│   │   │   ├── ModelsTests.swift
│   │   │   └── ModelsViewModelTests.swift
│   │   └── Settings/
│   │       └── ThemeTests.swift
│   ├── Shared/
│   │   ├── AnnotationModelTests.swift
│   │   ├── FileManagerProtocolTests.swift
│   │   ├── ModelStructTests.swift
│   │   └── SwiftDataModelTests.swift
│   ├── Core/
│   │   ├── BindingExtensionTests.swift
│   │   └── GuidedCaptureTests.swift
│   └── Mocks/
│       ├── FileManagerMocks.swift
│       └── MockNetworkService.swift
│
├── Configuration/                          # (unchanged)
├── docs/                                   # (unchanged)
├── Requirements/                           # (unchanged)
└── project.yml                             # (unchanged)
```

---

## Detailed Migration Steps

### Phase 1: Delete Duplicate Files (Low Risk)

**Goal:** Eliminate the 5 identical duplicate files from the project root. The canonical versions in `GuidedCaptureShared/` are kept.

| Delete (root)               | Keep (GuidedCaptureShared)                        |
|----------------------------|--------------------------------------------------|
| `./FileManagerProtocol.swift` | `GuidedCaptureShared/Utilities/FileManagerProtocol.swift` |
| `./Models.swift`            | `GuidedCaptureShared/Models/Models.swift`         |
| `./Theme.swift`             | `GuidedCaptureShared/Models/Theme.swift`          |
| `./User.swift`              | `GuidedCaptureShared/Models/User.swift`           |
| `./PathConstants.swift`     | `GuidedCaptureShared/Utilities/PathConstants.swift` |

**Risk:** If the Xcode project references the root copies (not the Shared ones), removing them will break the build. Must check `project.pbxproj` file references first and update them to point to the Shared versions.

**Mitigation:** Before deleting, verify which file reference the Xcode project uses. If it uses the root copy, update the reference to the Shared copy first, then delete.

---

### Phase 2: Create Feature Directories & Move Root Files (Medium Risk)

**Goal:** Move the 9 remaining root-level feature files into proper feature folders under `GuidedCapture/Features/`.

Create directories:
```
GuidedCapture/Features/Models/Views/
GuidedCapture/Features/Models/ViewModels/
GuidedCapture/Features/Models/Models/
GuidedCapture/Features/Import/Views/
GuidedCapture/Features/Import/ViewModels/
GuidedCapture/Features/Import/Models/
GuidedCapture/Features/Settings/Views/
GuidedCapture/Features/Settings/ViewModels/
```

Move files:
| From (root)             | To                                                    |
|------------------------|-------------------------------------------------------|
| `ModelsView.swift`      | `GuidedCapture/Features/Models/Views/`                |
| `ModelsViewModel.swift`  | `GuidedCapture/Features/Models/ViewModels/`           |
| `ModelsModel.swift`      | `GuidedCapture/Features/Models/Models/`               |
| `ImportView.swift`       | `GuidedCapture/Features/Import/Views/`                |
| `ImportViewModel.swift`   | `GuidedCapture/Features/Import/ViewModels/`           |
| `ImportModel.swift`       | `GuidedCapture/Features/Import/Models/`               |
| `SettingsView.swift`      | `GuidedCapture/Features/Settings/Views/`              |
| `SettingsViewModel.swift`  | `GuidedCapture/Features/Settings/ViewModels/`         |
| `EditProfileView.swift`    | `GuidedCapture/Features/Settings/Views/`              |

**Risk:** Xcode project file references must be updated. Moving files on disk alone is not enough — `project.pbxproj` has hardcoded relative paths.

**Mitigation:** Use Xcode's "Move to group" or update `project.pbxproj` paths after moving. Build after each batch of moves.

---

### Phase 3: Organize GuidedCapture/ Into Sub-groups (Medium Risk)

**Goal:** Group the 28 files in `GuidedCapture/` into logical sub-folders.

Create directories:
```
GuidedCapture/App/
GuidedCapture/Features/Capture/Views/
GuidedCapture/Features/Capture/ViewModels/
GuidedCapture/Features/Capture/Models/
GuidedCapture/Features/Capture/Utilities/
GuidedCapture/Features/Onboarding/Views/
GuidedCapture/Features/Onboarding/ViewModels/
GuidedCapture/SharedUI/
```

Move files:

**App/ (2 files):**
- `GuidedCaptureSampleApp.swift` → `GuidedCapture/App/`
- `ContentView.swift` → `GuidedCapture/App/`

**Features/Capture/Views/ (9 files):**
- `CapturePrimaryView.swift`
- `CaptureOverlayView.swift`
- `CaptureOverlayView+Buttons.swift`
- `CaptureOverlayView+LocalizedString.swift`
- `LoadGuidedCaptureView.swift`
- `ModelView.swift`
- `FeedbackView.swift`
- `HelpPageView.swift`
- `ReconstructionPrimaryView.swift`

**Features/Capture/ViewModels/ (3 files):**
- `AppDataModel.swift`
- `AppDataModel+Orbit.swift`
- `AppDataModel+State.swift`

**Features/Capture/Models/ (2 files):**
- `ShotFileInfo.swift`
- `CaptureFolderManager.swift`

**Features/Capture/Utilities/ (3 files):**
- `FeedbackMessages.swift`
- `TimedMessageList.swift`
- `UntilProcessingCompleteFilter.swift`

**Features/Onboarding/Views/ (5 files):**
- `OnboardingView.swift`
- `OnboardingTutorialView.swift`
- `OnboardingTutorialView+LocalizedString.swift`
- `OnboardingButtonView.swift`
- `OnboardingButtonView+LocalizedString.swift`

**Features/Onboarding/ViewModels/ (1 file):**
- `OnboardingStateMachine.swift`

**SharedUI/ (3 files):**
- `PlayerView.swift`
- `ProgressBarView.swift`
- `TutorialVideoView.swift`

---

### Phase 4: Reorganize Tests (Low Risk)

**Goal:** Mirror the new feature structure in the test directory.

Create directories:
```
GuidedCaptureTests/Features/Import/
GuidedCaptureTests/Features/Models/
GuidedCaptureTests/Features/Settings/
GuidedCaptureTests/Shared/
GuidedCaptureTests/Core/
GuidedCaptureTests/Mocks/       (rename from mocks/)
```

Move files:
| From                              | To                                        |
|----------------------------------|-------------------------------------------|
| `ImportTests.swift`               | `Features/Import/`                        |
| `ImportViewModelTests.swift`       | `Features/Import/`                        |
| `ModelsTests.swift`                | `Features/Models/`                        |
| `ModelsViewModelTests.swift`        | `Features/Models/`                        |
| `ThemeTests.swift`                  | `Features/Settings/`                      |
| `AnnotationModelTests.swift`        | `Shared/`                                 |
| `FileManagerProtocolTests.swift`    | `Shared/`                                 |
| `ModelStructTests.swift`            | `Shared/`                                 |
| `SwiftDataModelTests.swift`         | `Shared/`                                 |
| `BindingExtensionTests.swift`       | `Core/`                                   |
| `GuidedCaptureTests.swift`          | `Core/`                                   |
| `mocks/FileManagerMocks.swift`      | `Mocks/`                                  |
| `mocks/MockNetworkService.swift`    | `Mocks/`                                  |

---

### Phase 5: Update Xcode Project (Required After Each Phase)

After each phase, the `project.pbxproj` file must be updated to reflect the new file locations. This can be done by:

1. **Option A (Recommended):** Use `project.yml` with XcodeGen to regenerate `project.pbxproj` from the new file structure. Since `project.yml` already exists in the repo, this is likely the intended workflow.
2. **Option B:** Manually update file references in `project.pbxproj`.
3. **Option C:** Remove and re-add files in Xcode's project navigator after moving them on disk.

---

## Execution Order

| Step | Phase | What | Risk | Verification |
|------|-------|------|------|-------------|
| 1 | 1 | Check which duplicate files Xcode references | None | Read project.pbxproj |
| 2 | 1 | Delete 5 duplicate root files | Low | Build succeeds |
| 3 | 2 | Create feature dirs, move 9 root files | Medium | Build succeeds |
| 4 | 3 | Create sub-dirs in GuidedCapture/, move 28 files | Medium | Build succeeds |
| 5 | 4 | Reorganize test files | Low | Tests pass |
| 6 | 5 | Update project.pbxproj (or regenerate via XcodeGen) | Medium | Full build + test |
| 7 | — | Update CLAUDE.md to reflect new structure | None | — |

---

## Key Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Xcode project references break | Build fails | Update `project.pbxproj` after each move; build incrementally |
| Swift imports break | Build fails | No imports change — all files are in the same target/module |
| Git history lost for moved files | Hard to trace changes | Use `git mv` for all moves to preserve history |
| Tests fail after reorganization | CI breaks | Run tests after each phase |
| XcodeGen `project.yml` out of sync | Can't regenerate project | Update `project.yml` to match new structure |

---

## What This Plan Does NOT Change

- **No code modifications** — only file moves and deletions
- **No renaming** of types, functions, or files
- **No architectural changes** to AppDataModel (splitting it would be a separate task)
- **GuidedCaptureVision/** and **GuidedCaptureWidgets/** — unchanged (separate targets)
- **GuidedCaptureShared/** internal organization — unchanged (already well-structured)
