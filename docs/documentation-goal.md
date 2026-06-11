# Documentation Goal

This documentation pass is for future agents and maintainers who need to navigate Ortio quickly, choose the correct owner before editing, and avoid breaking persistence, capture, or UI lifecycle boundaries.

## Goal

Create repository-local documentation that makes the active Ortio iOS app easy to understand and safe to change.

The documentation should answer:

- What is the supported app and build graph?
- Which folder owns each major workflow?
- How do captured and imported models move through the app?
- Where are SwiftData and filesystem writes allowed?
- Which local rules should an agent read before editing a folder?
- What tests or simulator checks should verify common changes?

## Scope

This pass covers the active production app in `Ortio/`, the active test target in `OrtioTests/`, and durable docs under `docs/`.

Historical prototypes, removed targets, and inactive branches are out of scope unless future work explicitly reintroduces them.

## Completion Bar

Documentation is considered good enough for this pass when:

- `README.md` points readers to active architecture and workflow docs.
- `docs/README.md` indexes the active docs and local agent guides.
- `docs/architecture.md` explains ownership, app structure, data flow, persistence boundaries, and tests with diagrams.
- `docs/workflows.md` gives practical steps for common changes.
- Important ownership folders have local `AGENTS.md` files.
- Central contracts have DocC comments where the lack of comments previously made behavior hard to trust.
- Stale active-doc references to old project names or paths are removed.
