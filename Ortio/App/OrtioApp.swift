/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Top-level app structure of the view hierarchy.
*/

import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct OrtioApp: App {
    static let subsystem: String = "com.example.apple-samplecode.Ortio"

    @StateObject private var themeController = ThemeController()
    @Query private var users: [User]
    private var themeRefreshKey: String { users.first?.theme.rawValue ?? "missing-user" }

    var body: some Scene {
        WindowGroup {
            if #available(iOS 17.0, *) {
                ContentView()
                    .environmentObject(themeController)
                    .preferredColorScheme(themeController.selectedTheme.colorScheme)
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
                    .task(id: themeRefreshKey) {
                        themeController.applyStoredTheme(from: users)
                    }
            }
        }.modelContainer(for: [Models.self, CapturedModelMetadata.self, User.self])
    }
}
