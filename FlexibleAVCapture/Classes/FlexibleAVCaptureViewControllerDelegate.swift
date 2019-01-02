//
//  FlexibleAVCaptureViewControllerDelegate.swift
//  FlexibleAVCapture
//
//  Created by Natsuki HARAI on 2018/12/24.
//

import Foundation

public protocol FlexibleAVCaptureViewControllerDelegate {
    
    func didCapture(withFileURL fileURL: URL) -> Void
    
}
