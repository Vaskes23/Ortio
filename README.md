# Ortio iOS Capture App

Ortio currently supports one production app target: the iOS capture app built from `Ortio.xcodeproj`.

The repo previously contained planned shared-framework and visionOS scaffolds. Those prototypes are now archived under [DeferredPrototypes/README.md](/Users/matyasvascak/Desktop/Code/Ortio/DeferredPrototypes/README.md) and are not part of the supported build, test, or release flow.

## Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| iOS Capture App | Active | Supported product target |
| Unit Tests | Active | `OrtioTests` is the authoritative test bundle |
| Shared Framework Prototype | Archived | Deferred, not compiled |
| visionOS Prototype | Archived | Deferred, not compiled |
| Cloud Sync / Supabase | Deferred | Prototype docs retained for later work |

## Supported Project Structure

```text
/
├── Ortio/                  iOS app source
├── OrtioTests/             Active XCTest bundle
├── docs/                   Project and historical documentation
├── DeferredPrototypes/     Archived shared/visionOS prototype code
├── project.yml             XcodeGen manifest
└── Ortio.xcodeproj         Generated Xcode project
```

## Build and Test

```bash
xcodegen generate

xcodebuild test \
  -project Ortio.xcodeproj \
  -scheme Ortio \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture Notes

- `AppDataModel` is capture-flow state only.
- Theme and user settings are owned by a dedicated settings/theme layer.
- Filesystem and SwiftData mutations for the library/import flows go through repository types.
- `OrtioTests` is the only supported automated test target.

## Historical Prototype Material

Prototype shared-framework and visionOS work is archived and intentionally excluded from the live build:

- [DeferredPrototypes/Projects/OrtioShared](/Users/matyasvascak/Desktop/Code/Ortio/DeferredPrototypes/Projects/GuidedCaptureShared)
- [DeferredPrototypes/Projects/OrtioVision](/Users/matyasvascak/Desktop/Code/Ortio/DeferredPrototypes/Projects/GuidedCaptureVision)

Related prototype docs are still kept under `docs/` for reference, but they should be read as historical notes rather than active setup instructions.
