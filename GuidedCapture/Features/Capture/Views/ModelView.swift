/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A wrapper for QuickLook that shows the reconstructed USDZ model file
 using SwiftUI’s native .quickLookPreview() modifier.
*/

import QuickLook
import SwiftUI

public struct ModelView: View {
    let modelFile: URL
    let endCaptureCallback: () -> Void

    @State private var previewURL: URL?

    public init(modelFile: URL, endCaptureCallback: @escaping () -> Void) {
        self.modelFile = modelFile
        self.endCaptureCallback = endCaptureCallback
        self._previewURL = State(initialValue: modelFile)
    }

    public var body: some View {
        Color.black
            .ignoresSafeArea()
            .quickLookPreview($previewURL)
            .onChange(of: previewURL) { _, newValue in
                if newValue == nil {
                    endCaptureCallback()
                }
            }
    }
}
