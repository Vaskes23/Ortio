/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Top-level app structure of the view hierarchy.
*/

import SwiftUI
import SwiftData

@main
struct GuidedCaptureSampleApp: App {
    static let subsystem: String = "com.example.apple-samplecode.GuidedCapture"

    @StateObject private var appModel = AppDataModel()

    var body: some Scene {
        WindowGroup {
            if #available(iOS 17.0, *) {
                ContentView()
                    .environmentObject(appModel)
            }
        }.modelContainer(for: [Models.self, User.self])
    }
}
