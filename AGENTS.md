# AGENTS.md

This file is the primary development guide for agents working in Ortio. Keep it current when architecture, build targets, or conventions change.

## Project Overview

Ortio is a SwiftUI iOS app for 3D object capture, model import, model library management, notes, settings, and profile customization. The supported production code lives in `Ortio/`, with tests in `OrtioTests/`.

Historical or deferred prototype material may exist in the repository, but it is not part of the supported app flow unless the user explicitly asks to work on it.

## Collaboration Rules

- Always ask the user for specifics when the assignment is ambiguous. Question the request until the end goal, constraints, user-facing behavior, and technical tradeoffs are clear enough to implement responsibly.
- Before implementing a new feature, ask what the end goal is and provide a technical breakdown so the user stays in the loop.
- For meaningful behavior changes, define the expected outcome first, then write or update tests before implementation. Small visual-only tweaks do not always need tests, but still require a build or simulator sanity check.
- When the task is large enough, split discovery, implementation, and verification into focused work. Use a dedicated worker agent for implementation only after the goal and test expectations are clear.
- Do not optimize around merely passing tests. Use tests as the executable contract, then verify the actual app behavior and code quality around that contract.
- Never merge pull requests. Human approval is required for merges.

## Build And Project Generation

- `project.yml` is the source of truth for Xcode project structure. Run `xcodegen generate` after adding, removing, renaming, or moving files that should be part of the Xcode project.
- Active target: `Ortio`.
- Active test target: `OrtioTests`.
- Preferred simulator for local verification: iPhone 16 Pro when available.
- Use XcodeBuildMCP for build, test, run, simulator screenshots, and UI inspection when available.

Common commands:

```bash
xcodegen generate
xcodebuild test -project Ortio.xcodeproj -scheme Ortio -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Architecture

The app uses a feature-sliced layout:

```text
Ortio/
├── App/                 App entry point, model container, root navigation
├── Core/Repositories/   SwiftData and filesystem write boundaries
├── Features/            Feature modules grouped by user workflow
├── SharedUI/            Shared design-system and reusable UI components
├── Resources/           App resources
└── Assets.xcassets/     Asset catalog
```

Current app root:

- `Ortio/App/OrtioApp.swift` wires SwiftData and shared app state.
- `Ortio/App/ContentView.swift` hosts the current root `NavigationStack`.
- `Ortio/Features/Home/Views/HomeDashboardView.swift` is the primary home/library shell.

Architecture and workflow docs:

- `docs/architecture.md` explains the current app structure, diagrams, data flow, persistence boundaries, and test map.
- `docs/workflows.md` gives task-oriented steps for common changes.
- `docs/README.md` indexes active docs and local `AGENTS.md` files.

Local agent guides:

- `Ortio/App/AGENTS.md`
- `Ortio/Core/AGENTS.md`
- `Ortio/Features/Capture/AGENTS.md`
- `Ortio/Features/Home/AGENTS.md`
- `Ortio/Features/Import/AGENTS.md`
- `Ortio/Features/Models/AGENTS.md`
- `Ortio/Features/Onboarding/AGENTS.md`
- `Ortio/Features/Settings/AGENTS.md`
- `Ortio/SharedUI/AGENTS.md`
- `OrtioTests/AGENTS.md`

## SwiftUI Patterns

- Prefer modern Observation on iOS 17+: `@Observable` models owned by `@State`.
- Use `@State` for local view state and `@Binding` for child mutation of parent-owned value state.
- Use `@Environment` for SwiftUI-provided values and shared app services with clear ownership.
- Keep views small and composed. Extract repeated or complex UI into focused subviews.
- Avoid adding new `EnvironmentObject` usage unless working in an existing legacy area that already depends on it.
- Prefer `.sheet(item:)` or route enums when presenting selected domain objects or mutually exclusive destinations.
- Use boolean presentation state only for truly binary UI.
- Keep async work in `.task`, `.task(id:)`, explicit user actions, or injected services. Do not launch live work from `body`.
- Cancel long-running tasks when views disappear or when newer work supersedes older work.

## Data And Service Boundaries

- Views may read SwiftData with `@Query`.
- SwiftData writes, file imports, deletes, renames, favorites, and note updates should go through repository types in `Ortio/Core/Repositories`.
- Filesystem work should stay behind actor-backed stores or repository protocols.
- View models and services should depend on protocols where that boundary improves testability.
- Do not bypass `LibraryRepositoryProtocol`, `LibraryFileStoreProtocol`, or `UserSettingsRepositoryProtocol` for behavior they already own.

## Documentation

- Use DocC-style documentation throughout the codebase for public, internal, and non-obvious types, properties, and methods.
- Prefer `///` comments that explain intent, invariants, lifecycle constraints, side effects, and threading assumptions.
- Do not add noisy comments that restate obvious syntax.
- When adding a protocol, document the role of the abstraction, expected caller, ownership rules, and test seam.
- When adding a SwiftUI view, document the screen intent when it is not obvious from the type name.
- When adding async code, document cancellation behavior and actor/threading assumptions.
- Keep folder-level `AGENTS.md` files short and specific. Add them only where local rules prevent expensive mistakes.

## Testing Standards

- Use Swift Testing for new and migrated tests. XCTest is legacy in this codebase and should not be expanded unless the user explicitly asks for a transitional migration step.
- Use SwiftData in-memory containers for persistence tests.
- Follow Arrange, Act, Assert structure in each test.
- Write tests before implementation for meaningful logic, data, repository, service, or state-machine changes.
- Prefer focused tests around the behavior being changed. Do not broaden tests just to exercise unrelated code.
- Document test fixtures and helper types with DocC when their purpose is not obvious.
- Keep tests deterministic: avoid live network calls, persistent filesystem side effects, clock dependence, or simulator-only UI timing when a unit-level seam exists.

## UI And Design System

- Shared visual language belongs in `Ortio/SharedUI/OrtioDesignSystem.swift` or focused reusable components.
- Prefer system SwiftUI controls and platform-native behavior before custom chrome.
- Use Liquid Glass APIs only behind availability checks and provide reasonable fallbacks for older runtimes.
- Avoid one-off colors, shadows, and spacing when an existing design-system token fits.
- Verify non-trivial visual changes with a simulator screenshot.

## Agentic Development Workflow

1. Clarify the user goal, constraints, and expected end state.
2. Identify the relevant feature folder and read nearby code before proposing changes.
3. State the technical approach and test strategy.
4. For meaningful behavior, write or update tests first.
5. Implement the smallest coherent change that satisfies the goal.
6. Run targeted tests, then broader tests when the touched code affects shared behavior.
7. Build and run the simulator for UI or integration changes.
8. Summarize what changed, what was verified, and any remaining risk.

## Repository Hygiene

- Do not revert user changes unless explicitly instructed.
- Keep commits meaningful and scoped.
- Before any Codex-managed commit, push, or commit-and-push action, run the `documentation-creation` skill at `/Users/matyasvascak/.codex/skills/documentation-creation/SKILL.md` against the current branch changes. Apply any necessary documentation updates before creating the commit or pushing it.
- Do not stage unrelated local files such as IDE metadata or agent cache folders.
- Never commit generated junk, temporary files, or local-only server artifacts.
