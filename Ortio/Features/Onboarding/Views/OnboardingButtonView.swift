/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The buttons on the review screen.
*/

import RealityKit
import SwiftUI
import os

@available(iOS 17.0, *)
/// View that creates the buttons on the review screen depending on
/// `currentState` in `onboardingStateMachine`.
struct OnboardingButtonView: View {
    @EnvironmentObject var appModel: AppDataModel
    var session: ObjectCaptureSession
    @ObservedObject var onboardingStateMachine: OnboardingStateMachine
    @State private var userHasIndicatedObjectCannotBeFlipped: Bool? = nil
    @State private var userHasIndicatedFlipObjectAnyway: Bool? = nil

    var body: some View {
        VStack {
            HStack {
                CancelButton(buttonLabel: LocalizedString.cancel)
                Spacer()
            }

            Spacer()

            VStack(spacing: 0) {
                let currentStateInputs = onboardingStateMachine.currentStateInputs()
                if currentStateInputs.contains(where: { $0 == .continue(isFlippable: false) || $0 == .continue(isFlippable: true) }) {
                    CreateButton(buttonLabel: LocalizedString.continue,
                                 buttonLabelColor: OrtioDesignSystem.Palette.lightText,
                                 shouldApplyBackground: true,
                                 action: { transition(with: .continue(isFlippable: appModel.isObjectFlippable)) }
                    )
                }
                if currentStateInputs.contains(where: { $0 == .flipObjectAnyway }) {
                    CreateButton(buttonLabel: LocalizedString.flipAnyway,
                                 buttonLabelColor: OrtioDesignSystem.Palette.primaryAccent,
                                 action: {
                        userHasIndicatedFlipObjectAnyway = true
                        transition(with: .flipObjectAnyway)
                    })
                }
                if currentStateInputs.contains(where: { $0 == .skip(isFlippable: false) || $0 == .skip(isFlippable: true) }) {
                    CreateButton(buttonLabel: LocalizedString.skip,
                                 buttonLabelColor: OrtioDesignSystem.Palette.primaryAccent,
                                 action: {
                        transition(with: .skip(isFlippable: appModel.isObjectFlippable))
                    })
                }
                if currentStateInputs.contains(where: { $0 == .finish }) {
                    let isComplete = onboardingStateMachine.currentState == .thirdSegmentComplete
                    CreateButton(buttonLabel: LocalizedString.finish,
                                 buttonLabelColor: isComplete ? OrtioDesignSystem.Palette.lightText : OrtioDesignSystem.Palette.primaryAccent,
                                 shouldApplyBackground: isComplete,
                                 showBusyIndicator: session.state == .finishing,
                                 action: { [weak session] in session?.finish() })
                }
                if currentStateInputs.contains(where: { $0 == .objectCannotBeFlipped }) {
                    CreateButton(buttonLabel: LocalizedString.cannotFlipYourObject,
                                 buttonLabelColor: OrtioDesignSystem.Palette.primaryAccent,
                                 action: {
                        userHasIndicatedObjectCannotBeFlipped = true
                        transition(with: .objectCannotBeFlipped)
                    })
                }
                if onboardingStateMachine.currentState == OnboardingState.tooFewImages ||
                    onboardingStateMachine.currentState == .secondSegmentComplete  ||
                    onboardingStateMachine.currentState == .thirdSegmentComplete {
                    CreateButton(buttonLabel: "", action: {})
                }
            }
            .padding(.bottom)
        }
    }

    private func reloadData() {
        switch onboardingStateMachine.currentState {
            case .firstSegment, .dismiss:
                appModel.setPreviewModelState(shown: false)
            case .secondSegment, .thirdSegment, .additionalOrbitOnCurrentSegment:
                beginNewOrbitOrSection()
            default:
                break
        }
    }

    private func beginNewOrbitOrSection() {
        if let userHasIndicatedObjectCannotBeFlipped = userHasIndicatedObjectCannotBeFlipped {
            appModel.hasIndicatedObjectCannotBeFlipped = userHasIndicatedObjectCannotBeFlipped
        }

        if let userHasIndicatedFlipObjectAnyway = userHasIndicatedFlipObjectAnyway {
            appModel.hasIndicatedFlipObjectAnyway = userHasIndicatedFlipObjectAnyway
        }

        if !appModel.isObjectFlippable && !appModel.hasIndicatedFlipObjectAnyway {
            session.beginNewScanPass()
        } else {
            session.beginNewScanPassAfterFlip()
            appModel.isObjectFlipped = true
        }
        appModel.setPreviewModelState(shown: false)
        appModel.orbitState = .initial
        appModel.orbit = appModel.orbit.next()
    }

    private func transition(with input: OnboardingUserInput) {
        guard onboardingStateMachine.enter(input) else {
            CreateButton.logger.log("Could not move to new state in User Guide state machine")
            return
        }
        reloadData()
    }
}

@available(iOS 17.0, *)
private struct CreateButton: View {
    static let logger = Logger(subsystem: OrtioApp.subsystem,
                               category: "OnboardingButtonView")

    @EnvironmentObject var appModel: AppDataModel
    let buttonLabel: String
    var buttonLabelColor: Color = OrtioDesignSystem.Palette.lightText
    var buttonBackgroundColor: Color = OrtioDesignSystem.Palette.primaryAccent
    var shouldApplyBackground = false
    var showBusyIndicator = false
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(
            action: {
                CreateButton.logger.log("\(buttonLabel) clicked!")
                action()
            },
            label: {
                ZStack {
                    if showBusyIndicator {
                        HStack {
                            Text(buttonLabel).hidden()
                            Spacer().frame(maxWidth: 48)
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(
                                    tint: shouldApplyBackground ? OrtioDesignSystem.Palette.lightText : OrtioDesignSystem.Palette.primaryText))
                        }
                    }
                    Text(buttonLabel)
                        .font(.headline)
                        .bold()
                        .foregroundColor(buttonLabelColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
            })
        .if(shouldApplyBackground) { view in
            view.background(RoundedRectangle(cornerRadius: 16.0).fill(buttonBackgroundColor))
        }
        .padding(.leading)
        .padding(.trailing)
        .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 380 : .infinity)
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

@available(iOS 17.0, *)
private struct CancelButton: View {
    static let logger = Logger(subsystem: OrtioApp.subsystem,
                               category: "CancelButton")

    @EnvironmentObject var appModel: AppDataModel
    let buttonLabel: String

    var body: some View {
        Button(
            action: {
                CancelButton.logger.log("Cancel button clicked!")
                appModel.setPreviewModelState(shown: false)
            },
            label: {
                Text(buttonLabel)
                    .font(.headline)
                    .bold()
                    .padding(30)
                    .foregroundColor(OrtioDesignSystem.Palette.primaryAccent)
            })
    }
}
