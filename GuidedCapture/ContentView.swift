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
                    Image(systemName: "house.lodge.fill")
                    Text("Models")
                }
            
            ImportView(viewModel: ImportViewModel())
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
