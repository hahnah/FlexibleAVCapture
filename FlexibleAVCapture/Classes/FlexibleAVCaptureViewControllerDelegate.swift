//
//  FlexibleAVCaptureViewControllerDelegate.swift
//  FlexibleAVCapture
//
//  Copyright 2019, hahnah
//

import Foundation

public protocol FlexibleAVCaptureViewControllerDelegate {
    
    func didCapture(withFileURL fileURL: URL) -> Void
    
}
