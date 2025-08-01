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
import Foundation
import QuickLook
import ARKit
import UniformTypeIdentifiers

@Model final class Models: Identifiable {
    @Attribute(.unique) var name: String
    var date: Date
    var imported: Bool
    var favorite: Bool
    var size: Double
    @Attribute(.unique) var model: URL
    
    init(name: String, date: Date, favorite: Bool, imported: Bool, size: Double, model: URL) {
        self.name = name
        self.date = date
        self.favorite = favorite
        self.imported = imported
        self.size = size
        self.model = model
    }
}

// MARK: - Spacing Constants
enum Spacing {
    static let grid: CGFloat = 16
    static let section: CGFloat = 24
}

struct ImportView: View {
    @ObservedObject var viewModel: ImportViewModel
    @State private var presentImporter = false
    @State private var selectedModelForPreview: ImportModel.IdentifiableURL?
    @State private var searchQuery = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @Query(sort: \Models.date, order: .reverse) var storedModels: [Models] = []
    
    var filteredModels: [Models] {
        guard !searchQuery.isEmpty else { return storedModels }
        return storedModels.filter { model in
            model.name.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                storageSection
                importedSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Import")
            .searchable(text: $searchQuery, prompt: "Search files")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .overlay(alignment: .bottomTrailing) {
                ImportButton(isPresented: $presentImporter)
            }
            .fileImporter(
                isPresented: $presentImporter,
                allowedContentTypes: [.usd, .usdz, .realityFile],
                allowsMultipleSelection: true,
                onCompletion: handleImport
            )
            .sheet(item: $selectedModelForPreview, onDismiss: {
                selectedModelForPreview = nil
            }) { item in
                ModelView(modelFile: item.url, endCaptureCallback: {
                    selectedModelForPreview = nil
                })
            }
        }
    }
    
    // MARK: - Storage Section
    private var storageSection: some View {
        Section("Storage location") {
            NavigationLink {
                StoragePickerView()
            } label: {
                Label("On My iPhone", systemImage: "externaldrive")
            }
        }
        .headerProminence(.increased)
    }
    
    // MARK: - Imported Files Section
    private var importedSection: some View {
        Section("Imported objects") {
            ForEach(filteredModels, id: \.name) { model in
                FileRow(model: model) {
                    selectedModelForPreview = ImportModel.IdentifiableURL(url: model.model)
                }
            }
            .onDelete(perform: deleteModel)
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
   
    func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                importSingleFile(url)
            }
        case .failure(let error):
            print("Import error: \(error)")
        }
    }
    
    private func importSingleFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to get access to the file")
            return
        }
        
        // Check if the model has already been imported
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
            
            // Unique folder for the model
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
    }
}


// MARK: - FileRow Component
struct FileRow: View {
    let model: Models
    let onPreview: () -> Void
    
    var body: some View {
        HStack {
            Label(model.name, systemImage: "cube.transparent")
                .lineLimit(1)
            Spacer()
            Text(model.date.formatted(.dateTime.day().month().year()))
                .foregroundStyle(.secondary)
                .font(.caption)
            Button(action: onPreview) {
                Image(systemName: "eye")
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Preview \(model.name)")
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Preview", systemImage: "eye") {
                onPreview()
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                // Handle individual delete - could be implemented later
            }
        }
    }
}

// MARK: - ImportButton Component
struct ImportButton: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(Spacing.grid)
                .background(.ultraThinMaterial, in: Circle())
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.trailing, Spacing.section)
        .padding(.bottom, 60)
        .sensoryFeedback(.impact, trigger: isPresented)
        .accessibilityLabel("Import new 3D model")
    }
}

// MARK: - StoragePickerView (Placeholder)
struct StoragePickerView: View {
    var body: some View {
        List {
            Section("Choose storage location") {
                Label("On My iPhone", systemImage: "iphone")
                Label("iCloud Drive", systemImage: "icloud")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Storage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ImportView(viewModel: ImportViewModel())
}
