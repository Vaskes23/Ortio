//
//  GuidedCaptureWidgetsLiveActivity.swift
//  GuidedCaptureWidgets
//
//  Created by Matyas Vascak on 27.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GuidedCaptureWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct GuidedCaptureWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GuidedCaptureWidgetsAttributes.self) { context in
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

extension GuidedCaptureWidgetsAttributes {
    fileprivate static var preview: GuidedCaptureWidgetsAttributes {
        GuidedCaptureWidgetsAttributes(name: "World")
    }
}

extension GuidedCaptureWidgetsAttributes.ContentState {
    fileprivate static var smiley: GuidedCaptureWidgetsAttributes.ContentState {
        GuidedCaptureWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: GuidedCaptureWidgetsAttributes.ContentState {
         GuidedCaptureWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: GuidedCaptureWidgetsAttributes.preview) {
   GuidedCaptureWidgetsLiveActivity()
} contentStates: {
    GuidedCaptureWidgetsAttributes.ContentState.smiley
    GuidedCaptureWidgetsAttributes.ContentState.starEyes
}
