# Ortio iOS Capture App

Ortio currently supports one production app target: the iOS capture app built from `Ortio.xcodeproj`.

Historical shared-framework, visionOS, widget, backend, and excluded-test prototype material has been removed from the active tree. Use Git history if that reference material is needed later.

## Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| iOS Capture App | Active | Supported product target |
| Unit Tests | Active | `OrtioTests` is the authoritative test bundle |
| Historical Prototypes | Removed | Available through Git history if needed |

## Supported Project Structure

```text
/
├── Ortio/                  iOS app source
├── OrtioTests/             Active Swift Testing bundle
├── docs/                   Project documentation
├── project.yml             XcodeGen manifest
└── Ortio.xcodeproj         Generated Xcode project
```

## Documentation

- [docs/README.md](/Users/matyasvascak/Desktop/Code/Ortio/docs/README.md): documentation index
- [docs/architecture.md](/Users/matyasvascak/Desktop/Code/Ortio/docs/architecture.md): current architecture, diagrams, ownership map, persistence boundaries, and test map
- [docs/workflows.md](/Users/matyasvascak/Desktop/Code/Ortio/docs/workflows.md): task-oriented guides for common app changes
- [AGENTS.md](/Users/matyasvascak/Desktop/Code/Ortio/AGENTS.md): top-level agent development guide

Feature and ownership-specific `AGENTS.md` files live near the code they govern. Read the closest one before editing a folder.

## Build and Test

```bash
xcodegen generate

xcodebuild test \
  -project Ortio.xcodeproj \
  -scheme Ortio \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Native Dictation

Ortio's notes dictation uses iOS Speech recognition with on-device recognition required. No local server, API key, or internet connection is needed, but the current recognition locale must support on-device speech recognition.

## Architecture Notes

- `AppDataModel` is capture-flow state only.
- Theme and user settings are owned by a dedicated settings/theme layer.
- Filesystem and SwiftData mutations for the library/import flows go through repository types.
- `OrtioTests` is the only supported automated test target.
