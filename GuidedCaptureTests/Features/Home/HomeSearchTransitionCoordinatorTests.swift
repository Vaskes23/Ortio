//
//  HomeSearchTransitionCoordinatorTests.swift
//  GuidedCaptureTests
//
//  Created by OpenAI on 08.04.2026.
//

import XCTest
@testable import Ortio

final class HomeSearchTransitionCoordinatorTests: XCTestCase {
    func testIdlePhaseShowsBrowseChrome() {
        let coordinator = HomeSearchTransitionCoordinator(phase: .idle)

        XCTAssertTrue(coordinator.showsTitle)
        XCTAssertTrue(coordinator.showsQuickActions)
        XCTAssertTrue(coordinator.showsBrowseSectionChrome)
        XCTAssertFalse(coordinator.usesSearchResults)
        XCTAssertFalse(coordinator.shellIsExpanded)
    }

    func testActivePhaseShowsExpandedSearchChrome() {
        let coordinator = HomeSearchTransitionCoordinator(phase: .active)

        XCTAssertTrue(coordinator.shellIsExpanded)
        XCTAssertTrue(coordinator.usesSearchResults)
        XCTAssertTrue(coordinator.showsSearchFieldContents)
        XCTAssertTrue(coordinator.showsCloseBubble)
        XCTAssertTrue(coordinator.showsCloseGlyph)
        XCTAssertFalse(coordinator.showsInlineAvatar)
        XCTAssertFalse(coordinator.showsBrowseSectionChrome)
    }

    func testCollapsingShellKeepsSearchResultsUntilIdle() {
        let coordinator = HomeSearchTransitionCoordinator(phase: .collapsingShell)

        XCTAssertTrue(coordinator.usesSearchResults)
        XCTAssertFalse(coordinator.showsBrowseSectionChrome)
        XCTAssertFalse(coordinator.showsQuickActions)
        XCTAssertFalse(coordinator.showsScanButton)
        XCTAssertFalse(coordinator.showsCloseBubble)
        XCTAssertTrue(coordinator.showsInlineAvatar)
        XCTAssertFalse(coordinator.shellIsExpanded)
    }
}
