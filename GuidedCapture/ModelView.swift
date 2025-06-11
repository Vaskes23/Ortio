/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A wrapper for AR QuickLook viewer that shows the reconstructed USDZ model
 file directly.
*/

import ARKit
import QuickLook
import SwiftUI
import UIKit
import os

/// SwiftUI wrapper around ``ARQuickLookController`` that previews a USDZ model.
public struct ModelView: View {
    /// URL of the model to preview.
    let modelFile: URL
    /// Called when the Quick Look controller is dismissed.
    let endCaptureCallback: () -> Void

    public var body: some View {
        ARQuickLookController(modelFile: modelFile, endCaptureCallback: endCaptureCallback)
    }
}

/// ``UIViewControllerRepresentable`` that hosts ``QLPreviewController`` for AR Quick Look.
public struct ARQuickLookController: UIViewControllerRepresentable {
    static let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem,
                                category: "ARQuickLookController")

    let modelFile: URL
    let endCaptureCallback: () -> Void

    /// Creates the wrapped ``QLPreviewController``.
    public func makeUIViewController(context: Context) -> QLPreviewControllerWrapper {
        let controller = QLPreviewControllerWrapper()
        controller.qlvc.dataSource = context.coordinator
        controller.qlvc.delegate = context.coordinator
        return controller
    }

    /// Creates the coordinator used as delegate and data source.
    public func makeCoordinator() -> ARQuickLookController.Coordinator {
        return Coordinator(parent: self)
    }

    public func updateUIViewController(_ uiViewController: QLPreviewControllerWrapper, context: Context) {}

    /// Delegate and data source for ``QLPreviewController``.
    public class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let parent: ARQuickLookController

        init(parent: ARQuickLookController) {
            self.parent = parent
        }

        public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.modelFile as QLPreviewItem
        }

        public func previewControllerWillDismiss(_ controller: QLPreviewController) {
            ARQuickLookController.logger.log("Exiting ARQL ...")
            parent.endCaptureCallback()
        }
    }
}

/// UIViewController wrapper that presents ``QLPreviewController`` once the view appears.
public class QLPreviewControllerWrapper: UIViewController {
    let qlvc = QLPreviewController()
    var qlPresented = false

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Present the Quick Look view controller only once.
        if !qlPresented {
            present(qlvc, animated: false, completion: nil)
            qlPresented = true
        }
    }
}
