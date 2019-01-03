//
//  ViewController.swift
//  FlexibleAVCapture
//
//  Copyright (c) 2019 hahnah. All rights reserved.
//

import UIKit
import FlexibleAVCapture
import Photos

class ViewController: UIViewController, FlexibleAVCaptureViewControllerDelegate {
    
    let flexibleAVCaptureVC: FlexibleAVCaptureViewController = FlexibleAVCaptureViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.showFlexibleAVCaptureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func showFlexibleAVCaptureView() {
        flexibleAVCaptureVC.flexibleCaptureDelegate = self
        self.present(flexibleAVCaptureVC, animated: true, completion: nil)
    }
    
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
                self.flexibleAVCaptureVC.present(alert, animated: true, completion: nil)
            }
        }
    }

}

