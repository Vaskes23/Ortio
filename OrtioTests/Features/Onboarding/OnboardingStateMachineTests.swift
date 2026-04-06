import Testing
@testable import Ortio

@Suite("Onboarding State Machine")
struct OnboardingStateMachineTests {
    @Test
    func initWithValidInitialStateKeepsState() {
        let machine = OnboardingStateMachine(.secondSegmentNeedsWork)
        #expect(machine.currentState == .secondSegmentNeedsWork)
    }

    @Test
    func initWithInvalidInitialStateFallsBackToFirstSegment() {
        let machine = OnboardingStateMachine(.dismiss)
        #expect(machine.currentState == .firstSegment)
    }

    @Test
    func enterValidTransitionMovesToExpectedState() {
        let machine = OnboardingStateMachine(.firstSegmentComplete)

        let didTransition = machine.enter(.continue(isFlippable: true))

        #expect(didTransition)
        #expect(machine.currentState == .flipObject)
    }

    @Test
    func enterAlternateBranchForNonFlippableObject() {
        let machine = OnboardingStateMachine(.firstSegmentComplete)

        let didTransition = machine.enter(.continue(isFlippable: false))

        #expect(didTransition)
        #expect(machine.currentState == .flippingObjectNotRecommended)
    }

    @Test
    func enterWithInvalidInputDoesNotChangeState() {
        let machine = OnboardingStateMachine(.firstSegmentComplete)

        let didTransition = machine.enter(.skip(isFlippable: true))

        #expect(!didTransition)
        #expect(machine.currentState == .firstSegmentComplete)
    }

    @Test
    func enterFromTerminalStateWithoutTransitionsReturnsFalse() {
        let machine = OnboardingStateMachine(.firstSegmentComplete)
        machine.currentState = .dismiss

        let didTransition = machine.enter(.finish)

        #expect(!didTransition)
        #expect(machine.currentState == .dismiss)
    }

    @Test
    func currentStateInputsReturnsExpectedInputs() {
        let machine = OnboardingStateMachine(.secondSegmentNeedsWork)
        let inputs = machine.currentStateInputs()

        #expect(inputs.count == 4)
        #expect(inputs.contains(.continue(isFlippable: true)))
        #expect(inputs.contains(.continue(isFlippable: false)))
        #expect(inputs.contains(.skip(isFlippable: true)))
        #expect(inputs.contains(.skip(isFlippable: false)))
    }

    @Test
    func resetWithValidStateSucceeds() {
        let machine = OnboardingStateMachine(.firstSegmentComplete)

        let didReset = machine.reset(to: .thirdSegmentComplete)

        #expect(didReset)
        #expect(machine.currentState == .thirdSegmentComplete)
    }

    @Test
    func resetWithInvalidStateFailsAndKeepsCurrentState() {
        let machine = OnboardingStateMachine(.firstSegmentComplete)

        let didReset = machine.reset(to: .dismiss)

        #expect(!didReset)
        #expect(machine.currentState == .firstSegmentComplete)
    }
}
