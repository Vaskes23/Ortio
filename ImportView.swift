//
//  ImportView.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 24.12.2023.
//

import Foundation
import TipKit
import SwiftUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import Foundation
import QuickLook
import ARKit
import UniformTypeIdentifiers

@Model final class Models{
    @Attribute(.unique) var name: String
    var date: Date
    var imported: Bool
    var size: Double
    @Attribute(.unique) var model: URL
    
    init(name: String, date: Date, imported: Bool, size: Double, model: URL) {
        self.name = name
        self.date = date
        self.imported = imported
        self.size = size
        self.model = model
    }
}
struct IdentifiableURL: Identifiable {
    let id: UUID = UUID()
    let url: URL
}

struct ImportView: View {
    @State private var presentImporter = false
    @State private var files: [URL] = []
    @State private var selectedModelForPreview: IdentifiableURL?
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Models.date, order: .reverse) var storedModels: [Models]
    
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
                                self.selectedModelForPreview = IdentifiableURL(url: model.model)
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
    
    private func deleteModel(at offsets: IndexSet) {
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
    
    
    private func handleImport(result: Result<URL, Error>) {
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
                let uniqueFolderName = createUniqueFolderName(from: creationDate)
                let modelFolderURL = rootDirectory.appendingPathComponent(uniqueFolderName, isDirectory: true)
                try fileManager.createDirectory(at: modelFolderURL, withIntermediateDirectories: true)
                
                let destinationURL = modelFolderURL.appendingPathComponent(url.lastPathComponent)
                try fileManager.copyItem(at: url, to: destinationURL)
                
                let fileDate = creationDate ?? Date()
                let fileSize = try fileManager.attributesOfItem(atPath: destinationURL.path)[.size] as? Double ?? 0
                let newModel = Models(name: url.lastPathComponent,
                                      date: fileDate,
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
    
    private func createUniqueFolderName(from date: Date?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = dateFormatter.string(from: date ?? Date())
        return "Model_\(dateString)"
    }
    
    
    private func createUniqueFileName(originalURL: URL) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let timeStamp = dateFormatter.string(from: Date())
        let randomSequence = UUID().uuidString.prefix(8)
        let fileExtension = originalURL.pathExtension
        return "\(timeStamp)_\(randomSequence).\(fileExtension)"
    }
    
    private func createNewScanDirectory() -> URL? {
        guard let capturesFolder = rootScansFolder() else {
            print("Can't get user document dir!")
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date())
        let newCaptureDir = capturesFolder
            .appendingPathComponent(timestamp, isDirectory: true)
        
        print("Creating capture path: \(newCaptureDir)")
        let capturePath = newCaptureDir.path
        do {
            try FileManager.default.createDirectory(atPath: capturePath,
                                                    withIntermediateDirectories: true)
            var url = URL(fileURLWithPath: capturePath)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
        } catch {
            print("Failed to create capture path: \(capturePath) with error: \(error)")
            return nil
        }
        
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: capturePath, isDirectory: &isDir)
        guard exists && isDir.boolValue else {
            return nil
        }
        
        return newCaptureDir
    }
    
    private func rootScansFolder() -> URL? {
        guard let documentsFolder = try? FileManager.default.url(for: .documentDirectory,
                                                                 in: .userDomainMask,
                                                                 appropriateFor: nil, create: false) else {
            return nil
        }
        return documentsFolder.appendingPathComponent("Scans/", isDirectory: true)
    }
}

#Preview {
    ImportView()
}
