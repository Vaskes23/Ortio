//
//  ModelsView.swift
//  ModelCapture
//
//  Created by Matyas Vascak on 23.12.2023.
//

import Foundation
import TipKit
import SwiftUI
import SwiftData
 
struct ModelsView: View {
    @State private var searchText = ""
    @State private var models: [IdentifiableURL] = [] // Array to hold .usdz files
    @State private var selectedModelForPreview: IdentifiableURL?
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBar(text: $searchText)
                    .padding()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        
                        ObjectCaptureButtonView()
                        
                        HelpView()
                        
                        // Remaining grid items as blue squares
                        ForEach(1..<30) { _ in
                            BlueSquare()
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Models")
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        TextField("Models, Notes, Help...", text: $text)
            .padding(7)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

struct HelpView: View {
    var body: some View{
        Button(action: {
            //TODO: To be implemented / shows HelpView
        }) {
            VStack{
                Image(systemName: "questionmark.circle")
                    .font(.largeTitle)
                    .padding(2)
                Text("Help")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.yellow)
    }
}

struct ObjectCaptureButtonView: View {
    @State private var showingLoadGuidedCaptureView = false
    
    var body: some View {
        Button(action: {
            //Show LoadGuidedCaptureView
            self.showingLoadGuidedCaptureView = true
        }) {
            VStack {
                Image(systemName: "camera")
                    .font(.largeTitle)
                    .padding(2)
                Text("New")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.blue)
        // Present the LoadGuidedCaptureView modally
        .sheet(isPresented: $showingLoadGuidedCaptureView) {
            LoadGuidedCaptureView()
        }
    }
}

struct BlueSquare: View {
    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .aspectRatio(1.5, contentMode: .fit)
            .cornerRadius(10)
    }
}


#Preview {
    ModelsView()
}
