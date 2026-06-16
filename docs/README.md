# Ortio Documentation

## Active Documentation

These docs describe the supported iOS app and the current stabilization work:

- [../README.md](/Users/matyasvascak/Desktop/Code/Ortio/README.md): current repo status and supported build/test flow
- [documentation-goal.md](/Users/matyasvascak/Desktop/Code/Ortio/docs/documentation-goal.md): scope and completion bar for the comprehensive documentation pass
- [architecture.md](/Users/matyasvascak/Desktop/Code/Ortio/docs/architecture.md): architecture explanation, diagrams, data flow, ownership map, and test map
- [workflows.md](/Users/matyasvascak/Desktop/Code/Ortio/docs/workflows.md): how-to guide for common development tasks
- [account-sync-goal.md](/Users/matyasvascak/Desktop/Code/Ortio/docs/account-sync-goal.md): Apple-only settings gate and compact Supabase profile storage contract

## Local Agent Guides

Read the nearest guide before editing a folder:

- [../AGENTS.md](/Users/matyasvascak/Desktop/Code/Ortio/AGENTS.md): project-wide rules
- [../Ortio/App/AGENTS.md](/Users/matyasvascak/Desktop/Code/Ortio/Ortio/App/AGENTS.md): app root, SwiftData container, root navigation, theme application
- [../Ortio/Core/AGENTS.md](/Users/matyasvascak/Desktop/Code/Ortio/Ortio/Core/AGENTS.md): repository, filesystem, SwiftData, and settings persistence boundaries
- [../Ortio/Features/Capture/AGENTS.md](/Users/matyasvascak/Desktop/Code/Ortio/Ortio/Features/Capture/AGENTS.md): Object Capture and photogrammetry lifecycle
- [../Ortio/Features/Home/AGENTS.md](/Users/matyasvascak/Desktop/Code/Ortio/Ortio/Features/Home/AGENTS.md): home shell, library aggregation, search, preview, notes, dictation
- [../Ortio/Features/Import/AGENTS.md](/Users/matyasvascak/Desktop/Code/Ortio/Ortio/Features/Import/AGENTS.md): document import flow
- [../Ortio/Features/Models/AGENTS.md](/Users/matyasvascak/Desktop/Code/Ortio/Ortio/Features/Models/AGENTS.md): SwiftData model semantics
- [../Ortio/Features/Onboarding/AGENTS.md](/Users/matyasvascak/Desktop/Code/Ortio/Ortio/Features/Onboarding/AGENTS.md): onboarding guidance and state-machine rules
- [../Ortio/Features/Settings/AGENTS.md](/Users/matyasvascak/Desktop/Code/Ortio/Ortio/Features/Settings/AGENTS.md): profile, theme, and preferences
- [../Ortio/SharedUI/AGENTS.md](/Users/matyasvascak/Desktop/Code/Ortio/Ortio/SharedUI/AGENTS.md): design-system and shared UI rules

## Removed Historical Material

Deferred shared-framework, visionOS, widget, backend, and excluded-test prototype material was removed from the active tree. Use Git history if those references are needed later.

## Current Supported Build Graph

- `Ortio`
- `OrtioTests`
