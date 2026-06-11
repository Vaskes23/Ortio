# Models Agent Guide

This folder owns model data types and legacy/model-list presentation surfaces.

## SwiftData Rules

- `Models` represents imported model records and sample seeded model records.
- `CapturedModelMetadata` stores editable metadata for captured model file URLs.
- Do not store captured model files as imported `Models` records unless product requirements intentionally merge those concepts.
- Normalize display names and notes at write boundaries so search and display behavior stay predictable.
- Keep unique URL attributes stable; migrations need focused tests.

## Presentation Rules

- Prefer the current Home library shell for new browsing behavior.
- Only extend legacy model-list views when the user explicitly asks to work in that surface.

## Verification

- Run `OrtioTests/Shared/SwiftDataModelTests.swift` and related model tests when changing SwiftData fields, normalization, or metadata behavior.
