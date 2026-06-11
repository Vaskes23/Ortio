# Core Agent Guide

This folder owns persistence and filesystem write boundaries. Treat it as a contract layer between UI/view models and durable state.

## Repository Rules

- Views may read SwiftData with `@Query`, but SwiftData writes should go through repository types here when the behavior is already represented by a repository.
- Filesystem work belongs behind actor-backed stores such as `LibraryFileStore`.
- Repository protocols are test seams. Document new protocols with role, caller expectations, ownership rules, and testing guidance.
- Keep repository APIs focused on user workflows, not view layout details.

## Library Boundaries

- `LibraryRepository` coordinates SwiftData writes and delegates filesystem work to `LibraryFileStore`.
- `LibraryFileStore` owns `Documents/Scans`, `Documents/Imports`, copied import files, scan directory creation, and cleanup.
- Do not bypass `PathConstants` when constructing scan/import paths.
- Preserve captured-vs-imported semantics:
  - captured model files are discovered from scan folders
  - captured metadata is stored in `CapturedModelMetadata`
  - imported files are copied to imports folders
  - imported metadata is stored on `Models`

## Settings Boundaries

- `UserSettingsRepository` owns settings persistence.
- Keep profile/theme writes in SwiftData.
- Keep simple preferences in `UserDefaults` unless product requirements change.

## Verification

- Use in-memory SwiftData containers for persistence tests.
- Use `FileManagerProtocol` or repository protocol mocks for filesystem behavior.
- Run focused tests under `OrtioTests/Core` after changing this folder.
