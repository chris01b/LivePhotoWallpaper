import AVFoundation
import Foundation

func addMetadataToVideo2() {
    // Input & output URLs
    let inputURL = URL(fileURLWithPath: "/Users/chris/Downloads/1_old.MOV")
    let outputURL = URL(fileURLWithPath: "/Users/chris/Downloads/2.MOV")
    let workingLivePhotoURL = URL(fileURLWithPath: "/path/to/working_live_photo.MOV") // Add the path to your working live photo

    // Check if the input file exists
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: inputURL.path) else {
        print("Input file does not exist at specified path.")
        return
    }

    // Delete output file if it exists
    if fileManager.fileExists(atPath: outputURL.path) {
        do {
            try fileManager.removeItem(at: outputURL)
        } catch {
            print("Failed to delete existing output file: \(error)")
            return
        }
    }

    // Load assets
    let asset = AVAsset(url: inputURL)
    let workingLivePhotoAsset = AVAsset(url: workingLivePhotoURL)

    let assetTrack = asset.tracks(withMediaType: .video).first
    guard assetTrack != nil else {
        print("Couldn't load video tracks.")
        return
    }

    let duration = asset.duration

    // Create composition
    let composition = AVMutableComposition()

    // Add video track to composition
    guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
        print("Couldn't add video track")
        return
    }

    do {
        try compositionTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration), of: assetTrack!, at: .zero)
    } catch {
        print("Error inserting time range: \(error)")
        return
    }

    // Add metadata tracks from working live photo
    for metadataTrack in workingLivePhotoAsset.tracks(withMediaType: .metadata) {
        let compositionMetadataTrack = composition.addMutableTrack(withMediaType: .metadata, preferredTrackID: kCMPersistentTrackID_Invalid)
        try? compositionMetadataTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration), of: metadataTrack, at: .zero)
    }

    // Create exporter
    let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)
    exporter?.outputURL = outputURL
    exporter?.outputFileType = .mov

    // Add a run loop to keep the main thread alive until the export completes
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
