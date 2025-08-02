# ``IOSModelCapture``

IOSModelCapture is a sample iOS app that demonstrates guided 3D model capture with LiDAR.

## Project Structure

- `Configuration/` – Build configuration files like `SampleCode.xcconfig`.
- `GuidedCapture/` – Core app views, models, and resources for capturing and reviewing scans.
- `GuidedCaptureWidgets/` – Widget extension including live activity support.
- `GuidedCaptureTests/` – Unit tests covering models, view models, and utilities.
- Root Swift files – Supporting models and views:
  - `ImportModel.swift`, `ImportView.swift`, `ImportViewModel.swift`
  - `ModelsModel.swift`, `ModelsView.swift`, `ModelsViewModel.swift`
  - `SettingsView.swift`, `FileManagerProtocol.swift`

## Engineering Optimization Protocol

This protocol outlines a five-step process to improve and refine project workflows—including code, designs, or processes—ensuring efficiency and necessity.

1. **Question Requirements**
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

Apply these steps iteratively (once per Sprint) to maintain a lean and efficient project.

