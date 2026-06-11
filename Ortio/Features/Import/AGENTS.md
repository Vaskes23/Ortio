# Import Agent Guide

This folder owns the user-facing model import flow.

## Rules

- Keep file picker and presentation state in `ImportView`.
- Keep import and delete behavior in `ImportViewModel`, routed through `LibraryRepositoryProtocol`.
- Preserve security-scoped resource handling in the repository path for external file URLs.
- Do not duplicate filesystem copy/delete logic in views.
- Imported models should remain SwiftData `Models` records pointing at files copied under `Documents/Imports`.

## Verification

- Update `OrtioTests/Features/Import` when import, duplicate detection, error reporting, or delete behavior changes.
- Use repository or file-manager seams instead of live document picker behavior in unit tests.
