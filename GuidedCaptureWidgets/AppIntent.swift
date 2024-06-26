//
//  AppIntent.swift
//  GuidedCaptureWidgets
//
//  Created by Matyas Vascak on 27.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}
