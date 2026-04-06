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
import RealityKit
import SwiftData


struct ContentView : View {
    var body: some View {
        TabView{
            ModelsView(viewModel: ModelsViewModel())
                .tabItem{
                    Label("Models", systemImage: "cube")
                }
            
            ImportView(viewModel: ImportViewModel())
                .tabItem{
                    Label("Import", systemImage: "tray.and.arrow.down")
                }
        }
        .tint(.accentColor)
    }
}

#Preview {
    ContentView()
}
