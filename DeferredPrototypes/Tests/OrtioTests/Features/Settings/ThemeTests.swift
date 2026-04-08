//
//  ThemeTests.swift
//  OrtioTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
@testable import Ortio

final class ThemeTests: XCTestCase {

    // MARK: - Theme Enum Tests
    
    func testThemeAllCases() {
        // Act
        let allCases = Theme.allCases
        
        // Assert
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.light))
        XCTAssertTrue(allCases.contains(.dark))
        XCTAssertTrue(allCases.contains(.system))
    }
    
    func testThemeIdentifiable() {
        // Act & Assert
        let lightTheme = Theme.light
        let darkTheme = Theme.dark
        let systemTheme = Theme.system
        
        XCTAssertEqual(lightTheme.id, "light")
        XCTAssertEqual(darkTheme.id, "dark")
        XCTAssertEqual(systemTheme.id, "system")
    }
    
    func testThemeDescription() {
        // Act & Assert
        XCTAssertEqual(Theme.light.description, "Light")
        XCTAssertEqual(Theme.dark.description, "Dark")
        XCTAssertEqual(Theme.system.description, "System")
    }
    
    func testThemeRawValue() {
        // Act & Assert
        XCTAssertEqual(Theme.light.rawValue, "light")
        XCTAssertEqual(Theme.dark.rawValue, "dark")
        XCTAssertEqual(Theme.system.rawValue, "system")
    }
    
    func testThemeCodable() throws {
        // Arrange
        let themes: [Theme] = [.light, .dark, .system]
        
        // Act
        let encoder = JSONEncoder()
        let data = try encoder.encode(themes)
        
        let decoder = JSONDecoder()
        let decodedThemes = try decoder.decode([Theme].self, from: data)
        
        // Assert
        XCTAssertEqual(decodedThemes, themes)
    }
    
    func testThemeEquality() {
        // Act & Assert
        XCTAssertEqual(Theme.light, Theme.light)
        XCTAssertEqual(Theme.dark, Theme.dark)
        XCTAssertEqual(Theme.system, Theme.system)
        XCTAssertNotEqual(Theme.light, Theme.dark)
        XCTAssertNotEqual(Theme.light, Theme.system)
        XCTAssertNotEqual(Theme.dark, Theme.system)
    }
    
    func testThemeHashable() {
        // Arrange
        let themes: Set<Theme> = [.light, .dark, .system]
        
        // Act & Assert
        XCTAssertEqual(themes.count, 3)
        XCTAssertTrue(themes.contains(.light))
        XCTAssertTrue(themes.contains(.dark))
        XCTAssertTrue(themes.contains(.system))
    }
    
    // MARK: - Theme Initialization Tests
    
    func testThemeInitFromRawValue() {
        // Act & Assert
        XCTAssertEqual(Theme(rawValue: "light"), .light)
        XCTAssertEqual(Theme(rawValue: "dark"), .dark)
        XCTAssertEqual(Theme(rawValue: "system"), .system)
        XCTAssertNil(Theme(rawValue: "invalid"))
    }

    // MARK: - Theme String Representation Tests
    
    func testThemeStringInterpolation() {
        // Act
        let lightString = "\(Theme.light)"
        let darkString = "\(Theme.dark)"
        let systemString = "\(Theme.system)"
        
        // Assert
        XCTAssertEqual(lightString, "light")
        XCTAssertEqual(darkString, "dark")
        XCTAssertEqual(systemString, "system")
    }
    
    // MARK: - Theme Array Operations Tests
    
    func testThemeArrayOperations() {
        // Arrange
        var themes: [Theme] = []
        
        // Act
        themes.append(.light)
        themes.append(.dark)
        themes.append(.system)
        
        // Assert
        XCTAssertEqual(themes.count, 3)
        XCTAssertEqual(themes[0], .light)
        XCTAssertEqual(themes[1], .dark)
        XCTAssertEqual(themes[2], .system)
    }
    
    func testThemeArrayFiltering() {
        // Arrange
        let themes: [Theme] = [.light, .dark, .system, .light, .dark]
        
        // Act
        let lightThemes = themes.filter { $0 == .light }
        let darkThemes = themes.filter { $0 == .dark }
        let systemThemes = themes.filter { $0 == .system }
        
        // Assert
        XCTAssertEqual(lightThemes.count, 2)
        XCTAssertEqual(darkThemes.count, 2)
        XCTAssertEqual(systemThemes.count, 1)
    }
    
    func testThemeArrayMapping() {
        // Arrange
        let themes: [Theme] = [.light, .dark, .system]
        
        // Act
        let descriptions = themes.map { $0.description }
        let rawValues = themes.map { $0.rawValue }
        
        // Assert
        XCTAssertEqual(descriptions, ["Light", "Dark", "System"])
        XCTAssertEqual(rawValues, ["light", "dark", "system"])
    }
    
    // MARK: - Theme Dictionary Tests
    
    func testThemeAsDictionaryKey() {
        // Arrange
        var themeDictionary: [Theme: String] = [:]
        
        // Act
        themeDictionary[.light] = "Light Mode"
        themeDictionary[.dark] = "Dark Mode"
        themeDictionary[.system] = "System Mode"
        
        // Assert
        XCTAssertEqual(themeDictionary[.light], "Light Mode")
        XCTAssertEqual(themeDictionary[.dark], "Dark Mode")
        XCTAssertEqual(themeDictionary[.system], "System Mode")
        XCTAssertEqual(themeDictionary.count, 3)
    }
    
    // MARK: - Theme Optional Tests
    
    func testThemeOptionalHandling() {
        // Arrange
        let optionalLight: Theme? = .light
        let optionalDark: Theme? = .dark
        let optionalNil: Theme? = nil
        
        // Act & Assert
        XCTAssertNotNil(optionalLight)
        XCTAssertNotNil(optionalDark)
        XCTAssertNil(optionalNil)
        
        if let theme = optionalLight {
            XCTAssertEqual(theme, .light)
        } else {
            XCTFail("Optional light theme should not be nil")
        }
        
        if let theme = optionalDark {
            XCTAssertEqual(theme, .dark)
        } else {
            XCTFail("Optional dark theme should not be nil")
        }
    }
    
    // MARK: - Theme Switch Statement Tests
    
    func testThemeSwitchStatement() {
        // Test all cases in a switch statement
        let themes: [Theme] = [.light, .dark, .system]
        
        for theme in themes {
            switch theme {
            case .light:
                XCTAssertEqual(theme.description, "Light")
            case .dark:
                XCTAssertEqual(theme.description, "Dark")
            case .system:
                XCTAssertEqual(theme.description, "System")
            }
        }
    }
    
    // MARK: - Theme Performance Tests
    
    func testThemePerformance() {
        // Measure performance of theme operations
        measure {
            let themes: [Theme] = [.light, .dark, .system]
            for _ in 0..<1000 {
                _ = themes.map { $0.description }
                _ = themes.map { $0.rawValue }
                _ = themes.map { $0.id }
            }
        }
    }
}
