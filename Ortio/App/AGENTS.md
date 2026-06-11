# App Agent Guide

This folder owns the app entry point, SwiftData container setup, global theme application, and root navigation.

## Ownership

- `OrtioApp.swift` owns app-level environment setup and the SwiftData model container.
- `ContentView.swift` should remain a thin root shell that routes into the active product surface.
- `ThemeController.swift` applies the selected `Theme` to the app root.

## Rules

- Keep the model container schema in sync with SwiftData model types used by production code.
- Do not move feature-specific state into the app root.
- Prefer feature-owned routes or sheets from `HomeDashboardView` unless navigation must be global.
- Preserve theme application at the app root so all full-screen covers and sheets inherit it.
- If adding a new SwiftData model, update `OrtioApp.swift`, `project.yml` when needed, and tests that create in-memory containers.

## Verification

- Build the app after changing root environment, model container, or theme behavior.
- Run affected SwiftData/theme tests before broader verification.
