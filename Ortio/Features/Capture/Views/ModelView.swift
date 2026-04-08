/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A wrapper for QuickLook that shows the reconstructed USDZ model file
 using SwiftUI's native .quickLookPreview() modifier.
*/

import os
import QuickLook
import SwiftUI

public struct ModelView: View {
    let modelFile: URL
    let endCaptureCallback: () -> Void

    public init(modelFile: URL, endCaptureCallback: @escaping () -> Void) {
        self.modelFile = modelFile
        self.endCaptureCallback = endCaptureCallback
    }

    public var body: some View {
        ARQuickLookController(modelFile: modelFile, endCaptureCallback: endCaptureCallback)
    }
}

public struct ARQuickLookController: UIViewControllerRepresentable {
    static let logger = Logger(subsystem: OrtioApp.subsystem,
                                category: "ARQuickLookController")

    let modelFile: URL
    let endCaptureCallback: () -> Void

    public func makeUIViewController(context: Context) -> QLPreviewControllerWrapper {
        let controller = QLPreviewControllerWrapper()
        controller.qlvc.dataSource = context.coordinator
        controller.qlvc.delegate = context.coordinator
        return controller
    }

    public func makeCoordinator() -> ARQuickLookController.Coordinator {
        Coordinator(parent: self)
    }

    public func updateUIViewController(_ uiViewController: QLPreviewControllerWrapper, context: Context) {}

    public class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let parent: ARQuickLookController

        init(parent: ARQuickLookController) {
            self.parent = parent
        }

        public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            parent.modelFile as QLPreviewItem
        }

        public func previewControllerWillDismiss(_ controller: QLPreviewController) {
            ARQuickLookController.logger.log("Exiting ARQL ...")
            parent.endCaptureCallback()
        }
    }
}

public class QLPreviewControllerWrapper: UIViewController {
    let qlvc = QLPreviewController()
    var qlPresented = false

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !qlPresented {
            present(qlvc, animated: false, completion: nil)
            qlPresented = true
        }
    }
}
