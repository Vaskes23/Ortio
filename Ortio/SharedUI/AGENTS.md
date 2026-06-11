# Shared UI Agent Guide

This folder owns design-system tokens and reusable UI pieces used across features.

## Rules

- Prefer `OrtioDesignSystem` colors, radii, surfaces, and shadows over feature-local styling.
- Add shared components only when they serve more than one real call site or encode a platform fallback that should stay consistent.
- Keep Liquid Glass APIs behind availability checks with reasonable fallbacks.
- Do not put feature workflow state in shared UI components.
- Keep shared views small and dependency-light.

## Visual Verification

- Check phone-sized simulator screenshots for non-trivial shared UI changes.
- Confirm text fits and controls do not overlap in compact widths.
- Verify iOS fallback branches when changing availability-gated modifiers.
