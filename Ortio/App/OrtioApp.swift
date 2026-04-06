/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Top-level app structure of the view hierarchy.
*/

import SwiftUI
import SwiftData

@main
struct OrtioApp: App {
    static let subsystem: String = "com.example.apple-samplecode.Ortio"

    @StateObject private var appModel = AppDataModel()
    @Query private var users: [User]
    @Environment(\.modelContext) private var modelContext

    var body: some Scene {
        WindowGroup {
            if #available(iOS 17.0, *) {
                ContentView()
                    .environmentObject(appModel)
                    .onAppear {
                        appModel.loadTheme(from: users)
                    }
            }
        }.modelContainer(for: [Models.self, User.self])
    }
}
