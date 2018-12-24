//
//  ViewController.swift
//  FlexibleAVCapture
//
//  Created by hahnah on 12/09/2018.
//  Copyright (c) 2018 hahnah. All rights reserved.
//

import UIKit
import FlexibleAVCapture

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let vc: FlexibleAVCaptureViewController = FlexibleAVCaptureViewController()
        self.present(vc, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

