//
//  ViewController.swift
//  FlexibleAVCapture
//
//  Copyright (c) 2019 hahnah. All rights reserved.
//

import UIKit
import FlexibleAVCapture
import Photos

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async {
            let cameraViewController: CameraViewController = CameraViewController(cameraPosition: .back)
            cameraViewController.delegate = cameraViewController
            
            cameraViewController.maximumRecordDuration = CMTimeMake(value: 60, timescale: 1)
            cameraViewController.minimumFrameRatio = 0.16
            if cameraViewController.canSetVideoQuality(.high) {
                cameraViewController.setVideoQuality(.high)
            }
            
            self.present(cameraViewController, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
