import RealityKit
import SwiftUI
import os

@available(iOS 17.0, *)
/// The root of the SwiftUI view graph.
struct LoadOrtioView: View {
    static let logger = Logger(subsystem: OrtioApp.subsystem,
                                category: "ContentView")

    @StateObject private var appModel = AppDataModel()

    @State private var showReconstructionView: Bool = false
    @State private var showErrorAlert: Bool = false
    private var showProgressView: Bool {
        appModel.state == .completed || appModel.state == .restart || appModel.state == .ready
    }

    var body: some View {
        VStack {
            if appModel.state == .capturing {
                if let session = appModel.objectCaptureSession {
                    CapturePrimaryView(session: session)
                }
            } else if appModel.state == .unsupported {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Object capture is not supported on this device.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("A device with LiDAR Scanner is required.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else if showProgressView {
                CircularProgressView()
            }
        }
        .onChange(of: appModel.state) { _, newState in
            if newState == .failed {
                showErrorAlert = true
                showReconstructionView = false
            } else {
                showErrorAlert = false
                showReconstructionView = newState == .reconstructing || newState == .viewing
            }
        }
        .sheet(isPresented: $showReconstructionView) {
            if let folderManager = appModel.scanFolderManager {
                ReconstructionPrimaryView(outputFile: folderManager.modelsFolder.appendingPathComponent("model-mobile.usdz"))
            }
        }
        .alert(
            "Failed:  " + (appModel.error.map { String(describing: $0) } ?? "Unknown error"),
            isPresented: $showErrorAlert,
            actions: {
                Button("OK") {
                    LoadOrtioView.logger.log("Calling restart...")
                    appModel.state = .restart
                }
            },
            message: {}
        )
        .environmentObject(appModel)
    }
}

private struct CircularProgressView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .light ? .black : .white))
                Spacer()
            }
            Spacer()
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
struct LoadOrtioView_Previews: PreviewProvider {
    static var previews: some View {
        LoadOrtioView()
    }
}
#endif
