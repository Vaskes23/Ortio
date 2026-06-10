/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Encapsulated view support for the scanning progress meter.
*/

import Foundation
import SwiftUI
import RealityKit

struct ProgressBarView: View {
    @EnvironmentObject var appModel: AppDataModel
    // The progress value from 0 to 1 which describes how much coverage is done.
    var progress: Float
    var estimatedRemainingTime: TimeInterval?
    var processingStageDescription: String?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var numOfImages: Int = 0

    private var formattedEstimatedRemainingTime: String? {
        guard let estimatedRemainingTime = estimatedRemainingTime else { return nil }

        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        return formatter.string(from: estimatedRemainingTime)
    }

    private func loadImageCount() async {
        guard let folderManager = appModel.scanFolderManager else { return }
        let imagesFolder = folderManager.imagesFolder
        let count = await Task.detached {
            (try? FileManager.default.contentsOfDirectory(
                at: imagesFolder,
                includingPropertiesForKeys: nil
            ))?.filter { $0.pathExtension.uppercased() == "HEIC" }.count ?? 0
        }.value
        numOfImages = count
    }

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    Text(processingStageDescription ?? LocalizedString.processing)

                    Spacer()

                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .bold()
                        .monospacedDigit()
                }
                .font(.body)

                ProgressView(value: progress)
            }

            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .center) {
                    Image(systemName: "photo")

                    Text(String(numOfImages))
                        .frame(alignment: .bottom)
                        .hidden()
                        .overlay {
                            Text(String(numOfImages))
                                .font(.caption)
                                .bold()
                        }
                }
                .font(.subheadline)
                .padding(.trailing, 16)

                VStack(alignment: .leading) {
                    Text(LocalizedString.processingModelDescription)

                    Text(String.localizedStringWithFormat(LocalizedString.estimatedRemainingTime,
                                                          formattedEstimatedRemainingTime ?? LocalizedString.calculating))
                }
                .font(.subheadline)
            }
            .foregroundColor(OrtioDesignSystem.Palette.secondaryText)
        }
        .task {
            await loadImageCount()
        }
    }

    private struct LocalizedString {
        static let processing = NSLocalizedString(
            "Processing (Object Capture)",
            bundle: AppDataModel.bundleForLocalizedStrings,
            value: "Processing…",
            comment: "Processing title for object reconstruction."
        )

        static let processingModelDescription = NSLocalizedString(
            "Keep app running while processing. (Object Capture)",
            bundle: AppDataModel.bundleForLocalizedStrings,
            value: "Keep app running while processing.",
            comment: "Description displayed while processing models."
        )

        static let estimatedRemainingTime = NSLocalizedString(
            "Estimated time remaining: %@ (Object Capture)",
            bundle: AppDataModel.bundleForLocalizedStrings,
            value: "Estimated time remaining: %@",
            comment: "Estimated processing time to reconstruct object."
        )

        static let calculating = NSLocalizedString(
            "Calculating… (Estimated time, Object Capture)",
            bundle: AppDataModel.bundleForLocalizedStrings,
            value: "Calculating…",
            comment: "When estimated processing time isn't available yet."
        )
    }
}
