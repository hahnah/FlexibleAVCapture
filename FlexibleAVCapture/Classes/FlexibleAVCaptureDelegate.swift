//
//  FlexibleAVCaptureDelegate.swift
//  FlexibleAVCapture
//
//  Copyright (c) 2019 hahnah. All rights reserved.
//

import Foundation

public protocol FlexibleAVCaptureDelegate {
    
    func didCapture(withFileURL fileURL: URL) -> Void
    
}
