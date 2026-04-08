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

    @StateObject private var themeController = ThemeController()
    @Query private var users: [User]

    var body: some Scene {
        WindowGroup {
            if #available(iOS 17.0, *) {
                ContentView()
                    .environmentObject(themeController)
                    .preferredColorScheme(themeController.selectedTheme.colorScheme)
                    .onAppear {
                        themeController.applyStoredTheme(from: users)
                    }
            }
        }.modelContainer(for: [Models.self, CapturedModelMetadata.self, User.self])
    }
}
