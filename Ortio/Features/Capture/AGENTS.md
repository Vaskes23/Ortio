# Capture Agent Guide

This folder owns Object Capture, image capture, reconstruction, onboarding handoff, and capture-specific UI. Treat this area as lifecycle-sensitive.

## Core Rule

- Maintain the existing `ObservableObject` and `EnvironmentObject` pattern in Capture unless the user explicitly asks for a focused migration. `AppDataModel` coordinates Apple Object Capture and Photogrammetry lifecycles, and broad Observation rewrites can easily break session ownership, task cancellation, or device-specific behavior.

## State And Lifecycle

- `AppDataModel` is capture-flow state only. Do not move general home, library, import, settings, or model-management concerns into it.
- Keep capture session setup, listener tasks, reconstruction state, and cancellation behavior explicit.
- When replacing or restarting sessions, cancel prior listener tasks and release old session state deliberately.
- Preserve `@MainActor` isolation where UI-facing capture state is mutated.
- Keep `@EnvironmentObject` injection for capture views that already depend on `AppDataModel`.

## Filesystem And Persistence

- Do not write directly to arbitrary paths from views.
- Use the existing capture path helpers, file-store protocols, or repository seams for scan folder creation and model discovery.
- Keep `Scans/<session>/{Images,Snapshots,Models}` assumptions documented when adding new capture output.

## UI Patterns

- Capture views may use legacy Apple sample structure where it protects Object Capture behavior.
- Keep UI state local with `@State`/`@Binding` when it is purely visual.
- Keep capture overlays, buttons, help, feedback, and reconstruction UI split into focused files.
- Use DocC comments for non-obvious capture states, task ownership, and device/runtime assumptions.

## Testing

- Prefer Swift Testing for new capture tests.
- Follow Arrange, Act, Assert.
- Use protocol seams and deterministic fixtures for filesystem and capture utility tests.
- Do not require live camera, LiDAR, Object Capture sessions, or physical-device-only behavior in unit tests.
- Document fixtures and helpers with DocC when they encode capture folder or filename conventions.

## Before Editing

- Read `ViewModels/AppDataModel.swift` and related extensions before changing capture flow.
- Read the specific view being changed and nearby extension files before extracting UI.
- Ask the user for the expected capture behavior if the task could affect session state, reconstruction output, or physical-device requirements.
