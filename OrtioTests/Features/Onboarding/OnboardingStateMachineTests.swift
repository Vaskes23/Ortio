//
//  OnboardingStateMachineTests.swift
//  GuidedCaptureTests
//
//  Created by OpenAI on 08.04.2026.
//

import XCTest
@testable import Ortio

final class OnboardingStateMachineTests: XCTestCase {
    func testInitWithValidInitialStateKeepsState() {
        let machine = OnboardingStateMachine(.secondSegmentNeedsWork)
        XCTAssertEqual(machine.currentState, .secondSegmentNeedsWork)
    }

    func testInitWithInvalidInitialStateFallsBackToFirstSegment() {
        let machine = OnboardingStateMachine(.dismiss)
        XCTAssertEqual(machine.currentState, .firstSegment)
    }

    func testEnterValidTransitionMovesToExpectedState() {
        let machine = OnboardingStateMachine(.firstSegmentComplete)

        let didTransition = machine.enter(.continue(isFlippable: true))

        XCTAssertTrue(didTransition)
        XCTAssertEqual(machine.currentState, .flipObject)
    }

    func testEnterWithInvalidInputDoesNotChangeState() {
        let machine = OnboardingStateMachine(.firstSegmentComplete)

        let didTransition = machine.enter(.skip(isFlippable: true))

        XCTAssertFalse(didTransition)
        XCTAssertEqual(machine.currentState, .firstSegmentComplete)
    }

    func testResetWithValidStateSucceeds() {
        let machine = OnboardingStateMachine(.firstSegmentComplete)

        XCTAssertTrue(machine.reset(to: .thirdSegmentComplete))
        XCTAssertEqual(machine.currentState, .thirdSegmentComplete)
    }
}
