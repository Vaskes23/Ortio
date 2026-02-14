//
//  ModelBrowserView.swift
//  GuidedCaptureVision
//
//  Browse and select 3D models for viewing
//

import SwiftUI
import SwiftData
import GuidedCaptureShared

struct ModelBrowserView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Models.date, order: .reverse) private var models: [Models]

    var body: some View {
        NavigationStack {
            if models.isEmpty {
                ContentUnavailableView {
                    Label("No Models", systemImage: "cube")
                } description: {
                    Text("Import models from your iOS device to get started")
                }
            } else {
                List {
                    ForEach(models) { model in
                        NavigationLink {
                            ModelViewerView(model: model)
                        } label: {
                            ModelRow(model: model)
                        }
                    }
                }
            }
        }
        .navigationTitle("3D Models")
    }
}

struct ModelRow: View {
    let model: Models

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.name)
                .font(.headline)

            HStack {
                Label("\(formattedSize)", systemImage: "doc.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(model.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(model.size))
    }
}

#Preview {
    ModelBrowserView()
        .modelContainer(for: [Models.self], inMemory: true)
}
