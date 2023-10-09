import AVFoundation
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Generate a unique identifier for the asset
let assetIdentifier = UUID().uuidString

// This function adds metadata to a video asset
func addMetadataToVideo() {
    // Define constants related to the metadata that will be added
    let kKeySpaceQuickTimeMetadata = "mdta"
    let kKeyContentIdentifier = "com.apple.quicktime.content.identifier"
    let kKeyStillImageTime = "com.apple.quicktime.still-image-time"
    
    // Define the input and output URLs for the video processing
    let inputURL = URL(fileURLWithPath: "/Users/chris/Downloads/exported.MOV")
    let outputURL = URL(fileURLWithPath: "/Users/chris/Downloads/video_part.MOV")
    let workingLivePhotoURL = URL(fileURLWithPath: "/Users/chris/Downloads/NRNG9365.MOV")

    // Load video assets from provided URLs
    let asset = AVAsset(url: inputURL)
    let workingLivePhotoAsset = AVAsset(url: workingLivePhotoURL)

    // Ensure the asset is readable
    guard workingLivePhotoAsset.isReadable else {
        print("Failed to read working live photo asset.")
        return
    }

    // Create a new composition to mix video and metadata tracks
    let mixComposition = AVMutableComposition()

    // Create tracks in the composition for the video and metadata
    guard let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
        print("Couldn't add video track to the mix composition")
        return
    }

    // Create metadata tracks in the composition
    guard let metadataTrack1 = mixComposition.addMutableTrack(withMediaType: .metadata, preferredTrackID: kCMPersistentTrackID_Invalid),
          let metadataTrack2 = mixComposition.addMutableTrack(withMediaType: .metadata, preferredTrackID: kCMPersistentTrackID_Invalid) else {
        print("Couldn't add metadata tracks to the mix composition")
        return
    }

    // Define time ranges and insert them into the composition tracks
    do {
        try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: asset.tracks(withMediaType: .video)[0], at: .zero)
        try metadataTrack1.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: workingLivePhotoAsset.tracks(withMediaType: .metadata)[0], at: .zero)
        try metadataTrack2.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: workingLivePhotoAsset.tracks(withMediaType: .metadata)[1], at: .zero)
    } catch {
        print("Error inserting time ranges: \(error)")
        return
    }
    
    // Create metadata items to be added to the video
    let contentIdentifierItem = AVMutableMetadataItem()
    contentIdentifierItem.key = kKeyContentIdentifier as (NSCopying & NSObjectProtocol)
    contentIdentifierItem.keySpace = AVMetadataKeySpace(rawValue: kKeySpaceQuickTimeMetadata)
    contentIdentifierItem.value = assetIdentifier as (NSCopying & NSObjectProtocol)

    let stillImageTimeItem = AVMutableMetadataItem()
    stillImageTimeItem.key = kKeyStillImageTime as (NSCopying & NSObjectProtocol)
    stillImageTimeItem.keySpace = AVMetadataKeySpace(rawValue: kKeySpaceQuickTimeMetadata)
    stillImageTimeItem.value = 0 as (NSCopying & NSObjectProtocol)

    // Remove output file if it already exists to avoid conflicts
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: outputURL.path) {
        do {
            try fileManager.removeItem(at: outputURL)
        } catch {
            print("Failed to delete existing output file: \(error)")
            return
        }
    }

    // Set up and start the video export process
    let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetPassthrough)
    exporter?.outputURL = outputURL
    exporter?.outputFileType = .mov
    exporter?.metadata = [contentIdentifierItem, stillImageTimeItem]

    // Monitor the export process and handle its completion
    let runLoop = CFRunLoopGetCurrent()
    exporter?.exportAsynchronously {
        switch exporter?.status {
        case .completed:
            print("Export completed!")
        case .failed:
            if let error = exporter?.error {
                print("Export failed with error: \(error.localizedDescription)")
            } else {
                print("Export failed without a specific error.")
            }
        default:
            print("Export resulted in unknown state.")
        }
        CFRunLoopStop(runLoop)
    }
    CFRunLoopRun()
}

// This function extracts frames from a video and saves them as a HEIC image
func extractFramesAndSaveHEIC() {
    // Load the video asset from which frames will be extracted
    let videoURL = URL(fileURLWithPath: "/Users/chris/Downloads/exported.MOV")
    let videoAsset = AVAsset(url: videoURL)
    
    // Ensure the video contains video tracks
    guard videoAsset.tracks(withMediaType: .video).count > 0 else {
        print("No video tracks found in asset.")
        return
    }
    
    // Set up the image generator to extract frames from the video
    let frameRate: Int32 = 60
    let imageGenerator = AVAssetImageGenerator(asset: videoAsset)
    imageGenerator.requestedTimeToleranceBefore = CMTime(value: 1, timescale: frameRate)
    imageGenerator.requestedTimeToleranceAfter = CMTime(value: 1, timescale: frameRate)
    let durationInSeconds = CMTimeGetSeconds(videoAsset.duration)
    let totalFrames = Int(durationInSeconds * Double(frameRate))
    var images = [CGImage]()
    for frameIndex in 0..<totalFrames {
        let frameTime = CMTimeMake(value: Int64(frameIndex), timescale: frameRate)
        do {
            let imageRef = try imageGenerator.copyCGImage(at: frameTime, actualTime: nil)
            images.append(imageRef)
        } catch {
            print("Error generating frame at index \(frameIndex): \(error)")
        }
    }
    
    // Define metadata for the HEIC image
    let makerNote = NSMutableDictionary()
    makerNote.setObject(assetIdentifier, forKey: "17" as NSCopying)
    let metadata = NSMutableDictionary()
    metadata.setObject(makerNote, forKey: kCGImagePropertyMakerAppleDictionary as String as NSCopying)
    let exifVersion = NSMutableDictionary()
    exifVersion.setObject([2,2,1], forKey: kCGImagePropertyExifVersion as String as NSCopying)
    metadata.setObject(exifVersion, forKey: kCGImagePropertyExifDictionary as String as NSCopying)
    
    // Check if there are any images to save
    guard images.count > 0 else {
        print("No frames were extracted from the video.")
        return
    }
    
    // Save the extracted images as a HEIC file
    let url = URL(fileURLWithPath: "/Users/chris/Downloads/photo_part.HEIC")
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, AVFileType.heic.rawValue as CFString, images.count, nil) else {
        print("Failed to create image destination.")
        return
    }
    
    for image in images {
        CGImageDestinationAddImage(destination, image, metadata)
    }
    
    if !CGImageDestinationFinalize(destination) {
        print("Failed to save HEIC image.")
    } else {
        print("Saved HEIC image successfully!")
    }
}

addMetadataToVideo()
extractFramesAndSaveHEIC()
