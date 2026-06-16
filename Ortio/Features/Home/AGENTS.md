# Home Agent Guide

This folder owns the primary app shell: library browsing, filtering, search, preview, model notes, rename/favorite actions, share entry points, and native dictation UI.

## Ownership

- `HomeDashboardView.swift` is the production home/library shell.
- `LibraryItem.swift` defines the normalized item shown by home, search, preview, and editor sheets.
- `GlobalSearchViewModel.swift` merges captured filesystem results and imported SwiftData records.
- `NativeDictationService.swift` owns local audio transcription and recording support for notes.

## Library Rules

- Do not make Home views write directly to the filesystem.
- Route library mutations through `LibraryRepositoryProtocol`.
- Preserve the distinction between captured and imported items:
  - captured items use filesystem URLs plus optional `CapturedModelMetadata`
  - imported items use SwiftData `Models`
- Keep sorting behavior centralized in `GlobalSearchViewModel` unless a new feature explicitly needs a separate order.
- Validate preview URLs through `LibraryPreviewItem.previewableResult` before presenting `ModelView`.

## UI State Rules

- Keep purely visual state local with `@State`.
- Use item-based sheets for selected model actions.
- Keep search transition timing in `HomeSearchTransitionCoordinator`.
- Avoid moving capture/import/settings lifecycle state into Home; Home should launch those flows, not own them.

## Dictation Rules

- Native dictation is local on-device speech recognition.
- Preserve microphone and speech permission handling.
- Clean up temporary recordings on cancel and after failed flows where appropriate.
- Do not add network transcription without an explicit product decision.

## Verification

- Run focused tests in `OrtioTests/Features/Home` after search, dictation, preview, or transition changes.
- For layout changes, verify a simulator screenshot at phone size.
