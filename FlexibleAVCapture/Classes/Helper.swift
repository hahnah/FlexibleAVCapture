//
//  Helper.swift
//  FlexibleAVCapture
//
//  Copyright (c) 2019 hahnah. All rights reserved.
//

import Foundation
import UIKit
import AVKit

extension FlexibleAVCaptureViewController {
    
    internal func exportMovie(sourceURL: URL, destinationURL: URL, fileType: AVFileType, fullFrameRect: CGRect? = nil, croppingRect: CGRect? = nil, completion: (() -> Void)? = nil) -> Void {
        
        let avAsset: AVAsset = AVAsset(url: sourceURL)
        
        let videoTrack: AVAssetTrack = avAsset.tracks(withMediaType: AVMediaType.video)[0]
        let audioTracks: [AVAssetTrack] = avAsset.tracks(withMediaType: AVMediaType.audio)
        let audioTrack: AVAssetTrack? =  audioTracks.count > 0 ? audioTracks[0] : nil
        
        let mixComposition : AVMutableComposition = AVMutableComposition()
        
        let compositionVideoTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let compositionAudioTrack: AVMutableCompositionTrack? = audioTrack != nil
            ? mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
            : nil
        
        try! compositionVideoTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: avAsset.duration), of: videoTrack, at: CMTime.zero)
        try! compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: avAsset.duration), of: audioTrack!, at: CMTime.zero)
        
        compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
        
        var croppedVideoComposition: AVMutableVideoComposition? = nil
        if let _croppingRect: CGRect = croppingRect, let _fullFrameRect: CGRect = fullFrameRect {
            let (movieOrientation, _) : (UIImage.Orientation, Bool) = calculateOrientationFromTransform(videoTrack.preferredTransform)
            let needToSwap: Bool = movieOrientation == .left || movieOrientation == .leftMirrored || movieOrientation == .right || movieOrientation == .rightMirrored
            let movieSize: CGSize = videoTrack.naturalSize
            let intendedMovieSize: CGSize = needToSwap ? CGSize(width: movieSize.height, height: movieSize.width) : movieSize
            let intendedProtrudedSize: ProtrudedSize = calculateProtrudedSize(originalSize: intendedMovieSize, boundingSize: _fullFrameRect)
            let protrudedSize: ProtrudedSize = needToSwap ? ProtrudedSize(halfOfWidth: intendedProtrudedSize.halfOfHeight, halfOfHeight: intendedProtrudedSize.halfOfWidth) : intendedProtrudedSize
            let croppedOutSize: CroppedOutSize = CroppedOutSize(
                halfOfWidth: (movieSize.width - _croppingRect.width - protrudedSize.halfOfWidth * 2) * 0.5,
                halfOfHeight: (movieSize.height - _croppingRect.height - protrudedSize.halfOfHeight * 2) * 0.5)
            let transform: CGAffineTransform = videoTrack.preferredTransform.translatedBy(
                x: -_croppingRect.minX,
                y: -_croppingRect.minY + protrudedSize.halfOfHeight * 2 + croppedOutSize.halfOfHeight * 2)
            
            let layerInstruction: AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: compositionVideoTrack)
            layerInstruction.setCropRectangle(_croppingRect, at: CMTime.zero)
            layerInstruction.setTransform(videoTrack.preferredTransform, at: CMTime.zero)
            layerInstruction.setTransform(transform, at: CMTime.zero)
            
            let instruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: avAsset.duration)
            instruction.layerInstructions = [layerInstruction]
            croppedVideoComposition = AVMutableVideoComposition()
            croppedVideoComposition?.instructions = [instruction]
            croppedVideoComposition?.frameDuration = CMTimeMake(value: 1, timescale: 30)
            croppedVideoComposition?.renderSize = CGSize(width: needToSwap ? _croppingRect.height : _croppingRect.width, height: needToSwap ? _croppingRect.width : _croppingRect.height)
        }
        
        let assetExport = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetMediumQuality)
        assetExport?.outputFileType = fileType
        assetExport?.outputURL = destinationURL
        if let videoComposition = croppedVideoComposition {
            assetExport?.videoComposition = videoComposition
        }
        
        // delete if already exist
        if FileManager.default.fileExists(atPath: (assetExport?.outputURL?.path)!) {
            try! FileManager.default.removeItem(atPath: (assetExport?.outputURL?.path)!)
        }
        
        assetExport?.exportAsynchronously(completionHandler: {
            if let completionHandler = completion {
                completionHandler()
            }
        })
        
    }
    
    internal func calculateCroppingRect(movieSize: CGSize, movieOrientation: UIImage.Orientation, previewFrameRect: CGRect, fullFrameRect: CGRect) -> CGRect {
        
        let widthPercentage: CGFloat = previewFrameRect.width / fullFrameRect.width
        let heightPercentage: CGFloat  = previewFrameRect.height / fullFrameRect.height
        let isFullyWide: Bool = widthPercentage == 1.0 ? true : false
        let isFullyTall: Bool = heightPercentage == 1.0 ? true : false
        
        // PREMISE: At least one of widthPercentage and heightPercentage is 1.0.
        guard isFullyWide || isFullyTall else {
            return CGRect(origin: .zero, size: movieSize)
        }
        
        if isFullyWide {
            let heightRatioAgainstWidth: CGFloat = previewFrameRect.height / previewFrameRect.width
            let needToSwap: Bool = isPortrait(orientation: movieOrientation)
            let croppingSize: CGSize = CGSize(
                width: needToSwap ? (heightRatioAgainstWidth * widthPercentage * movieSize.height) : (widthPercentage * movieSize.width),
                height: needToSwap ? (widthPercentage * movieSize.height) : (heightRatioAgainstWidth * widthPercentage * movieSize.width))
            let croppingPoint: CGPoint = CGPoint(
                x: (movieSize.width - croppingSize.width) / 2.0,
                y: (movieSize.height - croppingSize.height) / 2.0)
            let croppingRect: CGRect = CGRect(x: croppingPoint.x, y: croppingPoint.y, width: croppingSize.width, height: croppingSize.height)
            return croppingRect
        } else { // In other words, fully tall (isFullyTall == 1.0)
            let needToSwap: Bool = isPortrait(orientation: movieOrientation)
            let intendedMovieSize: CGSize = needToSwap ? CGSize(width: movieSize.height, height: movieSize.width) : movieSize
            let protrudedSize: ProtrudedSize = calculateProtrudedSize(originalSize: intendedMovieSize, boundingSize: fullFrameRect)
            let intendedCroppingSize: CGSize = CGSize(
                width: widthPercentage * (intendedMovieSize.width - 2 * protrudedSize.halfOfWidth),
                height: intendedMovieSize.height)
            let croppingSize: CGSize = needToSwap ? CGSize(width: intendedCroppingSize.height, height: intendedCroppingSize.width) : intendedCroppingSize
            let croppingPoint: CGPoint = CGPoint(
                x: (movieSize.width - croppingSize.width) / 2.0,
                y: (movieSize.height - croppingSize.height) / 2.0)
            let croppingRect: CGRect = CGRect(x: croppingPoint.x, y: croppingPoint.y, width: croppingSize.width, height: croppingSize.height)
            return croppingRect
        }
        
    }
    
    private func calculateProtrudedSize(originalSize: CGSize, boundingSize: CGRect) -> ProtrudedSize {
        let movieAspectRatio: CGFloat = originalSize.height / originalSize.width
        let boundingAspectRatio: CGFloat = boundingSize.height / boundingSize.width
        var protrudedSize: ProtrudedSize = ProtrudedSize()
        if movieAspectRatio < boundingAspectRatio { // e.g. iPhone X or later
            let scale: CGFloat = boundingSize.height / originalSize.height
            let scaledWidth: CGFloat = originalSize.width * scale
            let scaledProtrudedWidth: CGFloat = scaledWidth - boundingSize.width
            protrudedSize.halfOfWidth = scaledProtrudedWidth * 0.5 / scale
            protrudedSize.halfOfHeight = 0.0
        } else if movieAspectRatio > boundingAspectRatio { // e.g. iPad series
            protrudedSize.halfOfWidth = 0.0
            protrudedSize.halfOfHeight = (originalSize.height - originalSize.width * boundingAspectRatio) * 0.5
        } else { // In other words, movieAspectRatio == frameAspectRatio. e.g. iPhone 6s - 8 Plus
            protrudedSize.halfOfWidth = 0.0
            protrudedSize.halfOfHeight = 0.0
        }
        return protrudedSize
    }
    
    private struct ProtrudedSize {
        var halfOfWidth: CGFloat
        var halfOfHeight: CGFloat
        init() {
            self.halfOfWidth = 0.0
            self.halfOfHeight = 0.0
        }
        init (halfOfWidth: CGFloat, halfOfHeight: CGFloat) {
            self.halfOfWidth = halfOfWidth
            self.halfOfHeight = halfOfHeight
        }
    }
    
    private typealias CroppedOutSize = ProtrudedSize
    
    private func isPortrait(orientation: UIImage.Orientation) -> Bool {
        return orientation == .left || orientation == .leftMirrored || orientation == .right || orientation == .rightMirrored
    }
    
    internal func calculateOrientationFromMediaURL(_ url: URL) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        let videoAsset: AVAsset = AVAsset(url: url)
        let videoTrack: AVAssetTrack = videoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let transform = videoTrack.preferredTransform
        let assetInfo = calculateOrientationFromTransform(transform)
        return assetInfo
    }
    
    internal func calculateOrientationFromTransform(_ transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
}
