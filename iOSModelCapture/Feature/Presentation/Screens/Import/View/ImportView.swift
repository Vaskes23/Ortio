//
//  ImportView.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 24.12.2023.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import QuickLook
import ARKit


struct ImportView: View {
    @ObservedObject var viewModel: ImportViewModel
    @State private var presentImporter = false
    @State private var files: [URL] = []
    @State private var selectedModelForPreview: ImportModel.IdentifiableURL?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Models.date, order: .reverse) var storedModels: [Models] = []
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Storage Options")) {
                    Button(action: {
                        presentImporter = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.to.line.alt")
                            Text("On My iPhone")
                        }
                    }
                    .fileImporter(isPresented: $presentImporter, allowedContentTypes: [.usd, .usdz, .realityFile], onCompletion: handleImport)
                }
                
                Section(header: Text("Imported objects")) {
                    ForEach(storedModels, id: \.name) { model in
                        HStack {
                            Text(model.name)
                            Spacer()
                            Text(model.date, style: .date)
                            Button(action: {
                                self.selectedModelForPreview = ImportModel.IdentifiableURL(url: model.model)
                            }) {
                                Image(systemName: "eye")
                                    .accessibilityLabel("Preview model")
                            }
                        }
                    }
                    .onDelete(perform: deleteModel)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Import objects")
            .navigationBarItems(trailing: EditButton())
            .sheet(item: $selectedModelForPreview, onDismiss: {
                
                self.selectedModelForPreview = nil
            }) { item in
                ModelView(modelFile: item.url, endCaptureCallback: {
                    self.selectedModelForPreview = nil
                })
            }
        }
    }
    
    func deleteModel(at offsets: IndexSet) {
       let fileManager = FileManager.default
       for index in offsets {
           let modelToDelete = storedModels[index]
           
           //Get the parent directory
           let fileURL = modelToDelete.model
           let parentDirectory = fileURL.deletingLastPathComponent()
           
           //Delete parent directory with it contents
           do {
               if fileManager.fileExists(atPath: parentDirectory.path) {
                   try fileManager.removeItem(at: parentDirectory)
                   print("Parent directory successfully deleted: \(parentDirectory.path)")
               }
           } catch {
               print("Error deleting parent directory: \(error)")
           }
           
           //Delete from the model context
           modelContext.delete(modelToDelete)
       }
   }
   
   func handleImport(result: Result<URL, Error>) {
       switch result {
       case .success(let url):
           guard url.startAccessingSecurityScopedResource() else {
               print("Failed to get access to the file")
               return
           }
           
           //Check if the model has already been imported
           let alreadyImported = storedModels.contains { $0.model == url }
           if alreadyImported {
               print("Model has already been imported")
               url.stopAccessingSecurityScopedResource()
               return
           }
           
           do {
               let fileManager = FileManager.default
               
               let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
               let rootDirectory = documentsDirectory.appendingPathComponent("Imports", isDirectory: true)
               
               if !fileManager.fileExists(atPath: rootDirectory.path) {
                   try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
               }
               
               //Unique folder for the model
               let creationDate = try url.resourceValues(forKeys: [.creationDateKey]).creationDate
               let uniqueFolderName = ImportViewModel.createUniqueFolderName(from: creationDate)
               let modelFolderURL = rootDirectory.appendingPathComponent(uniqueFolderName, isDirectory: true)
               try fileManager.createDirectory(at: modelFolderURL, withIntermediateDirectories: true)
               
               let destinationURL = modelFolderURL.appendingPathComponent(url.lastPathComponent)
               try fileManager.copyItem(at: url, to: destinationURL)
               
               let fileDate = creationDate ?? Date()
               let fileSize = try fileManager.attributesOfItem(atPath: destinationURL.path)[.size] as? Double ?? 0
               let newModel = Models(name: url.lastPathComponent,
                                     date: fileDate,
                                     favorite: false,
                                     imported: true,
                                     size: fileSize,
                                     model: destinationURL)
               
               modelContext.insert(newModel)
               
           } catch {
               print("File handling error: \(error)")
           }
           
           url.stopAccessingSecurityScopedResource()
           
       case .failure(let error):
           print("Import error: \(error)")
       }
   }
}

#Preview {
    ImportView(viewModel: ImportViewModel())
}
