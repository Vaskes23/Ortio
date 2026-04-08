//
//  ThemeControllerTests.swift
//  OrtioTests
//
//  Created by OpenAI on 08.04.2026.
//

import XCTest
@testable import Ortio

@MainActor
final class ThemeControllerTests: XCTestCase {
    func testApplyStoredThemeUsesFirstUserTheme() {
        let controller = ThemeController()
        let user = User(username: "alice", name: "Alice", theme: .dark, profileImage: nil)

        controller.applyStoredTheme(from: [user])

        XCTAssertEqual(controller.selectedTheme, .dark)
    }

    func testApplyThemeOverridesCurrentSelection() {
        let controller = ThemeController()

        controller.apply(theme: .light)
        controller.apply(theme: .system)

        XCTAssertEqual(controller.selectedTheme, .system)
    }
}
