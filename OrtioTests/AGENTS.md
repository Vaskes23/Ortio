# Test Quality Agent Guide

This folder owns automated tests for the active Ortio app. Tests should document behavior, protect architecture boundaries, and make future agent changes safer.

## Test Framework Direction

- Use Swift Testing for new and migrated tests.
- Do not add new XCTest files or expand existing XCTest coverage unless the user explicitly asks for a transitional migration step.
- Treat existing XCTest files as legacy code to migrate over time, not as the pattern to copy.
- Use SwiftData in-memory containers for persistence behavior.
- Do not use live network services, real user documents, or persistent global state.

## Test Structure

- Follow Arrange, Act, Assert in every test.
- Keep each test focused on one behavior.
- Name tests after the behavior being protected, not the implementation detail being called.
- Prefer one clear assertion cluster over long scenario tests that make failures hard to diagnose.
- Use helper methods only when they clarify repeated setup.

## SwiftData Tests

- Use in-memory SwiftData containers for all model and repository persistence tests.
- Seed only the models needed by the behavior under test.
- Avoid coupling tests to global app state or prior test execution.
- Cleanly separate fixture construction from the action being tested.

## Repository And Service Tests

- Test repositories through their public protocol-facing behavior.
- Use mocks, temp directories, or in-memory stores rather than live filesystem locations.
- Verify side effects that matter: saved models, deleted files, renamed metadata, propagated errors, and task cancellation.
- Keep protocol mocks small and explicit. Do not create overly broad mocks that hide behavior.

## SwiftUI State Tests

- Test view models, state machines, coordinators, and formatting logic directly when possible.
- Avoid UI timing tests unless the behavior cannot be verified at a lower level.
- For visual-only changes, prefer build/simulator screenshot verification rather than brittle unit tests.

## Documentation

- Use DocC-style `///` documentation for non-obvious test fixtures, mocks, and helpers.
- Document why a fixture exists when it encodes folder layout, sample model data, migration behavior, or SwiftData constraints.
- Do not add comments that merely repeat Arrange, Act, Assert labels; use those comments only when they improve readability.

## Agent Workflow

1. Ask what behavior must be protected before writing tests.
2. Write or update tests first for meaningful logic, repository, service, or state-machine changes.
3. Run the narrowest relevant test set.
4. Implement until those tests pass.
5. Run the broader suite when touching shared repositories, SwiftData models, app shell state, or shared UI contracts.
