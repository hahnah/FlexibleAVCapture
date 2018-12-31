//
//  ViewController.swift
//  FlexibleAVCapture
//
//  Created by hahnah on 12/09/2018.
//  Copyright (c) 2018 hahnah. All rights reserved.
//

import UIKit
import FlexibleAVCapture
import Photos

class ViewController: UIViewController, FlexibleAVCaptureViewControllerDelegate {
    
    let vc: FlexibleAVCaptureViewController = FlexibleAVCaptureViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.showFlexibleAVCaptureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showFlexibleAVCaptureView() {
        vc.flexibleCaptureDelegate = self
        self.present(vc, animated: true, completion: nil)
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
                self.vc.present(alert, animated: true, completion: nil)
            }
        }
    }

}

