# Onboarding Agent Guide

This folder owns review-screen onboarding guidance, tutorial media selection, onboarding buttons, and the onboarding state machine that interprets capture feedback.

## Rules

- Keep onboarding state transitions deterministic and testable in `OnboardingStateMachine`.
- Do not start Object Capture or photogrammetry work from onboarding views.
- Treat tutorial video/image names as resource contracts; verify assets exist before renaming or remapping states.
- Keep localized strings grouped in the existing localized-string extension files.
- Preserve the connection between `AppDataModel.Orbit`, Object Capture feedback, and tutorial state unless the capture guidance product flow changes.

## Verification

- Run onboarding state-machine tests after changing state transitions.
- For visual guidance changes, verify the review/onboarding screen on phone and iPad-sized layouts when possible.
