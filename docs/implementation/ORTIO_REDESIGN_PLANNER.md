# Ortio Redesign Planner

Use this checklist before implementing any new UI in the Figma-inspired Ortio shell.

## Feature Review Order

1. Identify the feature
   - Capture
   - Browse
   - Import
   - Search
   - Preview
   - Onboarding/help
   - Settings
2. Find the current owner in code
   - App shell: `GuidedCapture/App/ContentView.swift`
   - Captured library: `GuidedCapture/Features/Models/Views/ModelsView.swift`
   - Import flow: `GuidedCapture/Features/Import/Views/ImportView.swift`
   - Capture flow: `GuidedCapture/Features/Capture/Views/LoadGuidedCaptureView.swift`
   - Settings: `GuidedCapture/Features/Settings/Views/SettingsView.swift`
3. Confirm the storage owner
   - Captured models: `Documents/Scans/<timestamp>/Models/*.usdz`
   - Imported models: `Documents/Imports/<folder>/...` + SwiftData `Models`
   - User state: SwiftData `User`
   - Preferences: existing `UserDefaults` keys
4. Map the feature to the most appropriate Figma surface
   - `Overview`
   - `SearchView`
   - `SettingsView`
   - `ToolsSheet`
   - `ToolsExpandedSheet`
5. Judge fit
   - Reuse behavior if the Figma surface is a semantic match.
   - Reuse styling only if the Figma surface is only a visual match.
   - Reject the mapping if it forces Ortio into non-Ortio product semantics.
6. Protect contracts
   - Do not change `PathConstants`
   - Do not change SwiftData schema for `Models` or `User`
   - Do not change `AppDataModel.ModelState`
   - Do not change capture folder layout
   - Do not change Quick Look preview behavior
7. Define verification
   - List impacted unit tests
   - Add focused coverage for new aggregation or presentation state
   - Run `xcodebuild test -project GuidedCapture.xcodeproj -scheme GuidedCapture -destination 'platform=iOS Simulator,name=iPhone 16'`

## Required Output For Each Feature

- current owner
- storage owner
- chosen Figma mapping
- reason the mapping fits
- behavior that remains unchanged
- any new coordinator or presentation state
- build and test impact
