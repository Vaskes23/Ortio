/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that plays the tutorial.
*/

import SwiftUI

struct TutorialVideoView: View {
    @EnvironmentObject var appModel: AppDataModel
    let url: URL
    let isInReviewSheet: Bool
    @State var isShowing = false
    @State private var revealTask: Task<Void, Never>?
    @State private var captureAdvanceTask: Task<Void, Never>?

    private let textDelay: TimeInterval = 0.3
    private let animationDuration: TimeInterval = 4
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            PlayerView(
                url: url,
                isTransparent: true,
                isStacked: false,
                isInverted: isInReviewSheet && colorScheme == .light,
                shouldLoop: false
            )
            .opacity(isShowing ? 1 : 0)
            .overlay(alignment: .bottom) {
                if !isInReviewSheet {
                    Text(appModel.orbit.feedbackString(isObjectFlippable: appModel.isObjectFlippable))
                        .font(.headline)
                        .opacity(isShowing ? 1 : 0)
                        .padding(.bottom, 16)
                }
            }
            if isInReviewSheet {
                Spacer(minLength: 28)
            }
        }
        .foregroundColor(OrtioDesignSystem.Palette.lightText)
        .onAppear {
            startTutorialTasks()
        }
        .onDisappear { cancelTutorialTasks() }
    }

    private func startTutorialTasks() {
        cancelTutorialTasks()
        revealTask = Task {
            try? await Task.sleep(for: .seconds(textDelay))
            guard !Task.isCancelled else { return }
            withAnimation { isShowing = true }
        }
        guard !isInReviewSheet else { return }
        captureAdvanceTask = Task {
            try? await Task.sleep(for: .seconds(animationDuration))
            guard !Task.isCancelled else { return }
            appModel.orbitState = .capturing
        }
    }

    private func cancelTutorialTasks() {
        revealTask?.cancel()
        captureAdvanceTask?.cancel()
        revealTask = nil
        captureAdvanceTask = nil
    }
}
