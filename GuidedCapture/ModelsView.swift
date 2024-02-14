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
    @State private var models: [IdentifiableCaptureURL] = [] 
    @State private var selectedModelForPreview: IdentifiableCaptureURL?
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ObjectCaptureButtonView()
                        HelpView()
                        
                        ForEach(models.filter { $0.url.pathExtension == "usdz" }) { model in
                            // Replace BlueSquare with a view that previews the model
                            Button(action: {
                                self.selectedModelForPreview = model
                            }) {
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Models")
            .onAppear(perform: loadModelsFromDirectories)
            .sheet(item: $selectedModelForPreview, onDismiss: {
                self.selectedModelForPreview = nil
            }) { item in
                ModelView(modelFile: item.url, endCaptureCallback: {
                    self.selectedModelForPreview = nil
                })
            }
        }
    }
        

    
    private func loadModelsFromDirectories() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let modelURLs = try self.urlsInAllModelsFolders()
                let filteredModelURLs = modelURLs.filter { $0.pathExtension == "usdz" } // Filter for .usdz files if needed
                DispatchQueue.main.async {
                    self.models = filteredModelURLs.map { IdentifiableCaptureURL(url: $0) }
                }
            } catch {
                print("Error loading models: \(error.localizedDescription)")
                // Handle errors appropriately
            }
        }
    }

    private func urlsInAllModelsFolders() throws -> [URL] {
        let fileManager = FileManager.default
        let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let scansFolder = documentsDirectory.appendingPathComponent("Scans", isDirectory: true)

        var allModelURLs: [URL] = []
        let sessionDirectories = try fileManager.contentsOfDirectory(at: scansFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

        for sessionDir in sessionDirectories {
            let modelsFolder = sessionDir.appendingPathComponent("Models", isDirectory: true)
            let exists = fileManager.fileExists(atPath: modelsFolder.path, isDirectory: nil)
            if exists {
                let modelURLs = try fileManager.contentsOfDirectory(at: modelsFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                allModelURLs.append(contentsOf: modelURLs)
            }
        }

        return allModelURLs
    }
}

struct IdentifiableCaptureURL: Identifiable {
    let id = UUID()
    let url: URL
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
