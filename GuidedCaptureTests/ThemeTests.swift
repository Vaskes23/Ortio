//
//  ThemeTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Testing
@testable import Ortio

@Suite
struct ThemeTests {

    // MARK: - Theme Enum Tests

    @Test
    func themeAllCases() {
        // Act
        let allCases = Theme.allCases
        
        // Assert
        #expect(allCases.count == 3)
        #expect(allCases.contains(.light))
        #expect(allCases.contains(.dark))
        #expect(allCases.contains(.system))
    }

    @Test
    func themeIdentifiable() {
        // Act & Assert
        let lightTheme = Theme.light
        let darkTheme = Theme.dark
        let systemTheme = Theme.system
        
        #expect(lightTheme.id == "light")
        #expect(darkTheme.id == "dark")
        #expect(systemTheme.id == "system")
    }

    @Test
    func themeDescription() {
        // Act & Assert
        #expect(Theme.light.description == "Light")
        #expect(Theme.dark.description == "Dark")
        #expect(Theme.system.description == "System")
    }

    @Test
    func themeRawValue() {
        // Act & Assert
        #expect(Theme.light.rawValue == "light")
        #expect(Theme.dark.rawValue == "dark")
        #expect(Theme.system.rawValue == "system")
    }

    @Test
    func themeCodable() throws {
        // Arrange
        let themes: [Theme] = [.light, .dark, .system]
        
        // Act
        let encoder = JSONEncoder()
        let data = try encoder.encode(themes)
        
        let decoder = JSONDecoder()
        let decodedThemes = try decoder.decode([Theme].self, from: data)
        
        // Assert
        #expect(decodedThemes == themes)
    }

    @Test
    func themeEquality() {
        // Act & Assert
        #expect(Theme.light == Theme.light)
        #expect(Theme.dark == Theme.dark)
        #expect(Theme.system == Theme.system)
        #expect(Theme.light != Theme.dark)
        #expect(Theme.light != Theme.system)
        #expect(Theme.dark != Theme.system)
    }

    @Test
    func themeHashable() {
        // Arrange
        let themes: Set<Theme> = [.light, .dark, .system]
        
        // Act & Assert
        #expect(themes.count == 3)
        #expect(themes.contains(.light))
        #expect(themes.contains(.dark))
        #expect(themes.contains(.system))
    }
    
    // MARK: - Theme Initialization Tests
    
    @Test
    func themeInitFromRawValue() {
        // Act & Assert
        #expect(Theme(rawValue: "light") == .light)
        #expect(Theme(rawValue: "dark") == .dark)
        #expect(Theme(rawValue: "system") == .system)
        #expect(Theme(rawValue: "invalid") == nil)
    }
    
    
    // MARK: - Theme String Representation Tests
    
    @Test
    func themeStringInterpolation() {
        // Act
        let lightString = "\(Theme.light)"
        let darkString = "\(Theme.dark)"
        let systemString = "\(Theme.system)"
        
        // Assert
        #expect(lightString == "light")
        #expect(darkString == "dark")
        #expect(systemString == "system")
    }
    
    // MARK: - Theme Array Operations Tests
    
    @Test
    func themeArrayOperations() {
        // Arrange
        var themes: [Theme] = []
        
        // Act
        themes.append(.light)
        themes.append(.dark)
        themes.append(.system)
        
        // Assert
        #expect(themes.count == 3)
        #expect(themes[0] == .light)
        #expect(themes[1] == .dark)
        #expect(themes[2] == .system)
    }
    
    @Test
    func themeArrayFiltering() {
        // Arrange
        let themes: [Theme] = [.light, .dark, .system, .light, .dark]
        
        // Act
        let lightThemes = themes.filter { $0 == .light }
        let darkThemes = themes.filter { $0 == .dark }
        let systemThemes = themes.filter { $0 == .system }
        
        // Assert
        #expect(lightThemes.count == 2)
        #expect(darkThemes.count == 2)
        #expect(systemThemes.count == 1)
    }
    
    @Test
    func themeArrayMapping() {
        // Arrange
        let themes: [Theme] = [.light, .dark, .system]
        
        // Act
        let descriptions = themes.map { $0.description }
        let rawValues = themes.map { $0.rawValue }
        
        // Assert
        #expect(descriptions == ["Light", "Dark", "System"])
        #expect(rawValues == ["light", "dark", "system"])
    }
    
    // MARK: - Theme Dictionary Tests
    
    @Test
    func themeAsDictionaryKey() {
        // Arrange
        var themeDictionary: [Theme: String] = [:]
        
        // Act
        themeDictionary[.light] = "Light Mode"
        themeDictionary[.dark] = "Dark Mode"
        themeDictionary[.system] = "System Mode"
        
        // Assert
        #expect(themeDictionary[.light] == "Light Mode")
        #expect(themeDictionary[.dark] == "Dark Mode")
        #expect(themeDictionary[.system] == "System Mode")
        #expect(themeDictionary.count == 3)
    }
    
    // MARK: - Theme Optional Tests
    
    @Test
    func themeOptionalHandling() {
        // Arrange
        let optionalLight: Theme? = .light
        let optionalDark: Theme? = .dark
        let optionalNil: Theme? = nil
        
        // Act & Assert
        #expect(optionalLight != nil)
        #expect(optionalDark != nil)
        #expect(optionalNil == nil)

        if let theme = optionalLight {
            #expect(theme == .light)
        } else {
            #expect(false, "Optional light theme should not be nil")
        }

        if let theme = optionalDark {
            #expect(theme == .dark)
        } else {
            #expect(false, "Optional dark theme should not be nil")
        }
    }
    
    // MARK: - Theme Switch Statement Tests
    
    @Test
    func themeSwitchStatement() {
        // Test all cases in a switch statement
        let themes: [Theme] = [.light, .dark, .system]
        
        for theme in themes {
            switch theme {
            case .light:
                #expect(theme.description == "Light")
            case .dark:
                #expect(theme.description == "Dark")
            case .system:
                #expect(theme.description == "System")
            }
        }
    }

    // MARK: - Theme Performance Tests

    @Test
    func themePerformance() {
        // Simple performance-like loop
        let themes: [Theme] = [.light, .dark, .system]
        for _ in 0..<1000 {
            _ = themes.map { $0.description }
            _ = themes.map { $0.rawValue }
            _ = themes.map { $0.id }
        }
    }
}
