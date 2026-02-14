//
//  ModelViewerView.swift
//  GuidedCaptureVision
//
//  RealityKit-based 3D model viewer
//

import SwiftUI
import RealityKit
import GuidedCaptureShared

struct ModelViewerView: View {
    let model: Models

    @State private var viewModel: ModelViewerViewModel

    init(model: Models) {
        self.model = model
        self._viewModel = State(initialValue: ModelViewerViewModel(model: model))
    }

    var body: some View {
        ZStack {
            // RealityKit view (placeholder)
            RealityView { content in
                // TODO: Load USDZ model and create RealityKit scene
                // viewModel.loadModel(into: content)
            }
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        viewModel.handleScale(value.magnification)
                    }
            )
            .gesture(
                RotateGesture()
                    .onChanged { value in
                        viewModel.handleRotation(value.rotation)
                    }
            )

            // Overlay UI
            VStack {
                HStack {
                    Text(model.name)
                        .font(.title2)
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)

                    Spacer()

                    Button(action: viewModel.resetTransform) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                }
                .padding()

                Spacer()

                // Annotation controls (placeholder)
                HStack {
                    Button {
                        viewModel.showAnnotations.toggle()
                    } label: {
                        Label(
                            viewModel.showAnnotations ? "Hide Annotations" : "Show Annotations",
                            systemImage: viewModel.showAnnotations ? "eye.slash" : "eye"
                        )
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)

                    Spacer()

                    Button {
                        // TODO: Add annotation
                    } label: {
                        Label("Add Note", systemImage: "plus.circle")
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let previewModel = Models(
        name: "Sample Model",
        date: Date(),
        favorite: false,
        imported: true,
        size: 1024000,
        model: URL(fileURLWithPath: "/tmp/sample.usdz")
    )

    return ModelViewerView(model: previewModel)
}
