//
//  CameraViewController.swift
//  FlexibleAVCapture
//
//  Copyright © 2019 hahnah. All rights reserved.
//

import FlexibleAVCapture
import Photos

class CameraViewController: FlexibleAVCaptureViewController, FlexibleAVCaptureDelegate {
    
    func didCapture(withFileURL fileURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }) { saved, error in
            DispatchQueue.main.async {
                let success = saved && (error == nil)
                let title = success ? "Success" : "Error"
                let message = success ? "Movie saved." : "Failed to save movie."
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
}
