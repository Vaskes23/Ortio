//
//  OrtioVisionApp.swift
//  OrtioVision
//
//  visionOS app entry point
//

import SwiftUI
import SwiftData
import OrtioShared

@main
struct OrtioVisionApp: App {
    // SwiftData container configuration
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Models.self,
            User.self,
            Annotation.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)

        // Immersive space for AR viewing (to be implemented)
        ImmersiveSpace(id: "ImmersiveSpace") {
            // Placeholder for immersive AR view
            Text("Immersive AR View")
                .font(.extraLargeTitle)
        }
    }
}
