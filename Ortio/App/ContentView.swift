//
//  ContentView.swift
//  ModelCapture
//
//  Created by Matyas Vascak on 20.12.2023.
//
/*

Abstract:
Top-level SwiftUI container view for the entire app.
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            HomeDashboardView()
        }
        .tint(OrtioDesignSystem.Palette.primaryAccent)
    }
}

#Preview {
    ContentView()
}
