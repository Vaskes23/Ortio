//
//  ContentView.swift
//  GuidedCaptureVision
//
//  Main navigation view for visionOS app
//

import SwiftUI
import GuidedCaptureShared

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            ModelBrowserView()
                .tabItem {
                    Label("Models", systemImage: "cube.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Models.self, User.self, Annotation.self], inMemory: true)
}
