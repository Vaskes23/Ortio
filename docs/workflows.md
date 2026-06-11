# Ortio Development Workflows

This guide is for agents doing common tasks in Ortio. It favors practical steps over background explanation.

## Before Changing Code

1. Read `AGENTS.md`.
2. Read the nearest feature `AGENTS.md` if one exists.
3. Identify the owner folder before editing.
4. For behavior changes, find or add focused tests before implementation.
5. Keep `project.yml` as the source of truth for project structure.

## Add or Move a Swift File

1. Put the file in the feature, core, app, or shared folder that owns the behavior.
2. Update local documentation if the file introduces a new owner, lifecycle rule, or persistence boundary.
3. Run:

```bash
xcodegen generate
```

4. Run the most focused test target that covers the change.

## Change Library Behavior

Library behavior spans Home, Core repositories, SwiftData models, and filesystem paths.

1. Read:
   - `Ortio/Features/Home/Models/LibraryItem.swift`
   - `Ortio/Features/Home/ViewModels/GlobalSearchViewModel.swift`
   - `Ortio/Core/Repositories/LibraryRepository.swift`
   - `Ortio/Core/Repositories/LibraryFileStore.swift`
   - `Ortio/Features/Models/Models/Models.swift`
2. Decide whether the change affects captured models, imported models, or both.
3. Keep filesystem work in `LibraryFileStore`.
4. Keep SwiftData writes in `LibraryRepository` or a repository owned by the same boundary.
5. Preserve the split between captured files and imported records:
   - captured model files live under `Documents/Scans/<session>/Models`
   - captured editable metadata lives in `CapturedModelMetadata`
   - imported model records live in SwiftData `Models`
   - imported files live under `Documents/Imports/<folder>`
6. Add or update tests under `OrtioTests/Core` or `OrtioTests/Features/Home`.

## Change Capture Behavior

Capture is lifecycle-sensitive.

1. Read `Ortio/Features/Capture/AGENTS.md`.
2. Read `AppDataModel.swift` and relevant extensions before editing views.
3. Preserve `@MainActor` mutations for UI-facing capture state.
4. Keep session setup, listener tasks, cleanup, and reconstruction ownership explicit.
5. Do not require live camera, LiDAR, or Object Capture in unit tests.
6. For UI changes, build and run on a simulator. For real capture behavior, state when physical-device verification is still needed.

## Change Import Behavior

1. Read:
   - `Ortio/Features/Import/ViewModels/ImportViewModel.swift`
   - `Ortio/Core/Repositories/LibraryRepository.swift`
   - `Ortio/Core/Repositories/LibraryFileStore.swift`
2. Keep `ImportView` focused on presentation and file picker results.
3. Route import/delete mutations through `LibraryRepository`.
4. Preserve security-scoped resource handling for external URLs.
5. Test duplicates, failed copies, delete behavior, and SwiftData insertion when changing import logic.

## Change Settings or Profile Behavior

1. Read:
   - `Ortio/Features/Settings/ViewModels/SettingsViewModel.swift`
   - `Ortio/Core/Repositories/UserSettingsRepository.swift`
   - `Ortio/App/ThemeController.swift`
   - `Ortio/App/OrtioApp.swift`
2. Use `UserSettingsRepository` for SwiftData and `UserDefaults` writes.
3. Keep `ThemeController` as the global theme applier.
4. Test both persistence paths when behavior changes.

## Change Native Dictation

1. Read `Ortio/Features/Home/Services/NativeDictationService.swift`.
2. Keep remote-network transcription out unless the product direction explicitly changes.
3. Preserve on-device recognition requirements unless the user asks otherwise.
4. Keep temporary recording file cleanup explicit on cancellation.
5. Test permission, missing file, recognizer unavailable, empty transcript, and recorder state transitions with seams or deterministic fixtures.

## Change Shared UI

1. Read `Ortio/SharedUI/AGENTS.md`.
2. Prefer `OrtioDesignSystem` tokens over one-off colors, radii, and shadows.
3. Keep shared components generic enough for at least two real call sites.
4. Verify non-trivial visual changes in the simulator with a screenshot.

## Update Documentation

1. Use `docs/architecture.md` for cross-feature explanations.
2. Use this file for repeatable task guidance.
3. Use feature `AGENTS.md` files for local rules that prevent expensive mistakes.
4. Use DocC comments for contracts, invariants, threading, cancellation, and ownership.
5. Do not add empty documentation structures.
6. Verify paths, commands, and type names against the current branch before finishing.

## Verification Checklist

Use the smallest meaningful verification first, then broaden when the change touches shared behavior.

```bash
xcodegen generate
xcodebuild test -project Ortio.xcodeproj -scheme Ortio -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

For documentation-only changes, a full build is not always necessary. At minimum, check file links and grep for stale names introduced by the docs.
