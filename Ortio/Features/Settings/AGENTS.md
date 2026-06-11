# Settings Agent Guide

This folder owns profile editing, settings UI, theme selection, and settings view-model state.

## Persistence Rules

- Route persistence through `UserSettingsRepositoryProtocol`.
- Store profile and theme on SwiftData `User`.
- Store simple toggles in `UserDefaults` through `UserSettingsRepository`.
- Keep `ThemeController` in `Ortio/App` as the global theme applier.

## UI Rules

- Keep `SettingsViewModel` as the state boundary for settings screens.
- Avoid adding app-wide environment objects for settings unless an existing app-level owner needs them.
- Preserve the first-user assumption unless requirements introduce multi-profile support.

## Verification

- Run settings and theme tests after persistence, profile image, theme, or preference changes.
