//
//  OrtioWidgetsLiveActivity.swift
//  OrtioWidgets
//
//  Created by Matyas Vascak on 27.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct OrtioWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct OrtioWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OrtioWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension OrtioWidgetsAttributes {
    fileprivate static var preview: OrtioWidgetsAttributes {
        OrtioWidgetsAttributes(name: "World")
    }
}

extension OrtioWidgetsAttributes.ContentState {
    fileprivate static var smiley: OrtioWidgetsAttributes.ContentState {
        OrtioWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: OrtioWidgetsAttributes.ContentState {
         OrtioWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: OrtioWidgetsAttributes.preview) {
   OrtioWidgetsLiveActivity()
} contentStates: {
    OrtioWidgetsAttributes.ContentState.smiley
    OrtioWidgetsAttributes.ContentState.starEyes
}
