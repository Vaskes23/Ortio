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
            ModelsView()
                .tabItem{
                    Image(systemName: "house.lodge.fill")
                    Text("Models")
                }
            
            ImportView()
                .modelContainer(for: Models.self)
                .tabItem{
                    Image(systemName: "folder.fill")
                    Text("Import")
                }
        }
    }
}

#Preview {
    ContentView()
}
