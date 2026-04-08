//
//  HomeSearchTransitionCoordinator.swift
//  GuidedCapture
//
//  Created by OpenAI on 08.04.2026.
//

import CoreGraphics
import Foundation

struct HomeSearchTransitionCoordinator: Equatable {
    enum Phase: Equatable {
        case idle
        case expandingShell
        case revealingControls
        case active
        case hidingControls
        case collapsingShell
    }

    static let shellStageDuration: Duration = .milliseconds(150)
    static let controlsStageDuration: Duration = .milliseconds(85)
    static let hideControlsDuration: Duration = .milliseconds(70)
    static let collapseStageDuration: Duration = .milliseconds(170)

    var phase: Phase = .idle

    var showsTitle: Bool {
        phase == .idle
    }

    var showsQuickActions: Bool {
        phase == .idle
    }

    var showsBrowseSectionChrome: Bool {
        phase == .idle
    }

    var showsScanButton: Bool {
        phase == .idle
    }

    var usesSearchResults: Bool {
        phase != .idle
    }

    var shellIsExpanded: Bool {
        switch phase {
        case .idle, .collapsingShell:
            return false
        case .expandingShell, .revealingControls, .active, .hidingControls:
            return true
        }
    }

    var showsInlineAvatar: Bool {
        switch phase {
        case .idle, .expandingShell, .collapsingShell:
            return true
        case .revealingControls, .active, .hidingControls:
            return false
        }
    }

    var showsSearchFieldContents: Bool {
        phase == .active
    }

    var showsCloseBubble: Bool {
        switch phase {
        case .revealingControls, .active, .hidingControls:
            return true
        case .idle, .expandingShell, .collapsingShell:
            return false
        }
    }

    var showsCloseGlyph: Bool {
        phase == .active
    }

    var allowsSearchActivation: Bool {
        phase == .idle
    }

    var allowsTextFieldInteraction: Bool {
        phase == .active
    }

    var canBeginClosing: Bool {
        switch phase {
        case .revealingControls, .active, .hidingControls:
            return true
        case .idle, .expandingShell, .collapsingShell:
            return false
        }
    }

    var isTransitioning: Bool {
        switch phase {
        case .idle, .active:
            return false
        case .expandingShell, .revealingControls, .hidingControls, .collapsingShell:
            return true
        }
    }

    var listTopPadding: CGFloat {
        showsBrowseSectionChrome ? 0 : 10
    }

    var contentLiftOffset: CGFloat {
        usesSearchResults ? -10 : 0
    }
}
