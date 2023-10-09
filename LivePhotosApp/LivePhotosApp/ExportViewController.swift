import UIKit
import Photos

class ExportViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        savePhoto()
    }
    

    fileprivate func savePhoto() {
        
        guard let imageFileURL = Bundle.main.url(forResource: "photo_part", withExtension: "HEIC"),
              let videoFileURL = Bundle.main.url(forResource: "video_part", withExtension: "MOV")  else { print("file is nil");  return }
        
        let photoLibrary = PHPhotoLibrary.shared()

        photoLibrary.performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, fileURL: imageFileURL, options: nil)
            creationRequest.addResource(with: .pairedVideo, fileURL: videoFileURL, options: nil)
        },
        completionHandler: { success, error in
            if success {
                print("Live Photo saved successfully!")
            } else if let error = error {
                print("Error saving Live Photo to the library: \(error.localizedDescription)")
                
                // Cast the error to NSError to access the userInfo dictionary
                if let nsError = error as NSError? {
                    for (key, value) in nsError.userInfo {
                        print("\(key): \(value)")
                    }
                }
            }
        })
    }
}
