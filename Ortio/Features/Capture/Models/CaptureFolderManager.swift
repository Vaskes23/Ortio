/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that supports the creation, listing, and filename support of a capture folder.
*/

import Foundation
import os

class CaptureFolderManager: ObservableObject {
    static let logger = Logger(subsystem: OrtioApp.subsystem,
                                category: "CaptureFolderManager")

    private let logger = CaptureFolderManager.logger
    private let fileManager: FileManagerProtocol
    
//    @Query(sort: \CreatedModels.date, order: .reverse) var storedModels: [CreatedModels]

    // The top-level capture directory that contains Images and Snapshots subdirectories.
    // This sample automatically creates this directory at `init()` with timestamp.
    let rootScanFolder: URL

    // Subdirectory of `rootScanFolder` for images
    let imagesFolder: URL

    // Subdirectory of `rootScanFolder` for snapshots
    let snapshotsFolder: URL

    // Subdirectory to output model files.
    let modelsFolder: URL

    @Published var shots: [ShotFileInfo] = []

    init(layout: CaptureDirectoryLayout, fileManager: FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
        rootScanFolder = layout.rootScanFolder
        imagesFolder = layout.imagesFolder
        snapshotsFolder = layout.snapshotsFolder
        modelsFolder = layout.modelsFolder
    }

    func loadShots() async throws {
        logger.debug("Loading snapshots (async)...")

        var newShots: [ShotFileInfo] = []

        let imgUrls = try fileManager
            .contentsOfDirectory(at: imagesFolder,
                                 includingPropertiesForKeys: [],
                                 options: [.skipsHiddenFiles])
            .filter { $0.isFileURL
                && $0.lastPathComponent.hasSuffix(CaptureFolderManager.heicImageExtension)
            }
        for imgUrl in imgUrls {
            guard let shotFileInfo = ShotFileInfo(url: imgUrl) else {
                logger.error("Can't get shotId from url: \"\(imgUrl)\")")
                continue
            }

            newShots.append(shotFileInfo)
        }

        // Sorts and then makes the final replacement in the published array.
        newShots.sort(by: { $0.id < $1.id })
        shots = newShots
    }

    /// Retrieves the image id from of an existing file at a URL.\
    ///
    /// - Parameter url: URL of the photo for which this method returns the image id.
    /// - Returns: The image ID if `url` is valid; otherwise `nil`.
    static func parseShotId(url: URL) -> UInt32? {
        let photoBasename = url.deletingPathExtension().lastPathComponent
        logger.debug("photoBasename = \(photoBasename)")

        guard let endOfPrefix = photoBasename.lastIndex(of: "_") else {
            logger.warning("Can't get endOfPrefix!")
            return nil
        }

        let imgPrefix = photoBasename[...endOfPrefix]
        guard imgPrefix == imageStringPrefix else {
            logger.warning("Prefix doesn't match!")
            return nil
        }

        let idString = photoBasename[photoBasename.index(after: endOfPrefix)...]
        guard let id = UInt32(idString) else {
            logger.warning("Can't convert idString=\"\(idString)\" to uint32!")
            return nil
        }

        return id
    }

    // Returns the basename for file with the given `id`.
    static func imageIdString(for id: UInt32) -> String {
        String(format: "%@%04d", imageStringPrefix, id)
    }

    /// Returns the file URL for the HEIC image that matches the specified
    /// image id  in a specified output directory.
    ///
    /// - Parameters:
    ///   - outputDir: The directory where the capture session saves images.
    ///   - id: Identifier of an image.
    /// - Returns: `outputDir` URL if the image exists
    static func heicImageUrl(in outputDir: URL, id: UInt32) -> URL {
        outputDir
            .appendingPathComponent(imageIdString(for: id))
            .appendingPathExtension(heicImageExtension)
    }

    // Constants this sample appends in front of the capture id to get a file basename.
    private static let imageStringPrefix = "IMG_"
    private static let heicImageExtension = "HEIC"
}
