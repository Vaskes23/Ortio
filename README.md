# iOSModelCapture

This repository contains a sample project that demonstrates capturing and managing 3D models with LiDAR-enabled iOS devices. The codebase is written in Swift and organized as an Xcode project.

## Project structure

- `iOSModelCapture/` – main project folder
  - `Common/` – shared configuration files, app resources and utility classes
  - `Docs/` – DocC based developer documentation
  - `Feature/` – data models, mock implementations and the presentation layer
  - `GuidedCapture.xcodeproj/` – Xcode project configuration
  - `Preview Content/` – assets used in SwiftUI previews
  - `Tests/` – integration and unit tests
  - `Info.plist` – application configuration
  - `LICENSE/` – license information
- `ImportView.swift` and `SettingsView.swift` – example views placed at the repository root

See `Docs/README.md` for details on running the sample on a device.

## Engineering Optimization Protocol (EOP)

To keep the project lean and efficient, apply the following steps each sprint:

1. **Question Requirements** – ensure every requirement has a clear purpose and owner. Challenge vague or unnecessary tasks.
2. **Remove Unnecessary Elements** – aggressively cut steps or features that are not essential. Aim to trim at least 10% before considering additions.
3. **Simplify and Optimize** – streamline what remains so it is as simple and effective as possible. Only optimize what truly matters.
4. **Increase Speed** – accelerate workflows only after simplification. Avoid speeding up processes that shouldn't exist.
5. **Automate** – automate once the process is necessary, simplified and optimized. Avoid premature automation.

Iterate through these steps regularly to maintain a focused workflow.
