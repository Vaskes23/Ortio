# iOSModelCapture

This repository contains a sample project that demonstrates capturing and managing 3D models with LiDAR-enabled iOS devices. The codebase is written in Swift and organized as an Xcode project.

## Project structure

- `iOSModelCapture/` – main project folder
  - `Common/` – shared configuration files, app resources and utilities
  - `Docs/` – DocC based developer documentation
  - `Feature/` – data models, mocks and the presentation layer
  - `GuidedCapture.xcodeproj/` – Xcode project configuration
  - `Preview Content/` – assets used in SwiftUI previews
  - `Tests/` – integration and unit tests
  - `Info.plist` – application configuration
  - `LICENSE` – license file
- `ImportView.swift` and `SettingsView.swift` – example views placed at the repository root

See `Docs/README.md` for details on running the sample on a device.

## Engineering Optimization Protocol (EOP)

Engineering Optimization Protocol outlines a five-step process to improve and refine project workflows—including code, designs, or processes—ensuring efficiency and necessity.

1. **Question Requirements**
   - Critically evaluate every requirement.
   - Ensure each requirement is clear, justified, and tied to a specific purpose & person.
   - Challenge vague or unnecessary requirements to avoid wasted effort.
2. **Remove Unnecessary Elements**
   - Aggressively eliminate parts or steps that aren’t essential.
   - If you’re not reinstating at least 10% of what you remove, you’re likely not cutting enough.
   - Start with the essentials, and build from there.
3. **Simplify and Optimize**
   - Streamline what remains after elimination.
   - Focus on making the process or component as simple and effective as possible.
   - Only optimize what is necessary.
4. **Increase Speed**
   - Accelerate the process or workflow only after completing the prior steps.
   - Avoid speeding up something that shouldn’t exist or hasn’t been simplified.
5. **Automate**
   - Implement automation as the final step.
   - Ensure the process is necessary, simplified, and optimized.
   - Avoid automating prematurely to prevent wasted effort on redundant systems.

Apply these steps iteratively (once per sprint) to maintain a lean and efficient project.
