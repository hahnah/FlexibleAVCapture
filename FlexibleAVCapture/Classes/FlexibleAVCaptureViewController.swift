//
//  FlexibleAVCaptureViewController.swift
//  FlexibleAVCapture
//
//  Copyright (c) 2019 hahnah. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

public class FlexibleAVCaptureViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    public var flexibleCaptureDelegate: FlexibleAVCaptureViewControllerDelegate? = nil
    public var maxDuration: Int64 = 60
    public var minimumFrameRatio: CGFloat {
        get {
            return self.minimumFrameRatio_
        }
        set(newRatio) {
            guard 0.0 <= newRatio && newRatio <= 1.0 else {
                debugPrint("Failed to set minimumFrameRatio. It should fulfill the condition 0 ≦ minimumFrameRatio ≦ 1.")
                return
            }
            self.minimumFrameRatio_ = newRatio
        }
    }
    public var allowResizing: Bool {
        get {
            return self.allowResizing_
        }
        set(ifAllow) {
            self.allowResizing_ = ifAllow
            if ifAllow {
                self.showResizingUIs()
            } else {
                self.hideResizingUIs()
            }
        }
    }
    
    private var minimumFrameRatio_: CGFloat = 0.34
    private var allowResizing_: Bool = true
    private var captureSession: AVCaptureSession? = nil
    private var videoLayer: AVCaptureVideoPreviewLayer? = nil
    private var slider: UISlider = UISlider()
    private var buttonForFullFrame: UIButton = UIButton()
    private var buttonForSquareFrame: UIButton = UIButton()
    private var buttonForWideFrame: UIButton = UIButton()
    private var buttonForTallFrame: UIButton = UIButton()
    private var recordButton: UIButton!
    private var isRecording: Bool = false
    private var isVideoSaved: Bool = false
    private let boundaries: Array<Float> = [0.0,
                                    1.0 / 3.0,
                                    2.0 / 3.0,
                                    1.0]
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.showCameraPreview()
        self.applyPresetPreviewFrame()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    public func forceResize(withResizingParameter resizingParameter: Float) {
        guard 0 <= resizingParameter && resizingParameter <= 1.0 else {
            debugPrint("Illegal parameter in forceResize. withResizingParameter should fulill the condition 0 ≦ withResizingParameter ≦ 1.")
            return
        }
        self.forcePreviewFrameToResize(withResizingParameter: resizingParameter)
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        let tempDirectory: URL = URL(fileURLWithPath: NSTemporaryDirectory())
        let reoutputFileURL: URL = tempDirectory.appendingPathComponent("mytemp.mov")
        
        let tempVideoTrack: AVAssetTrack = AVAsset(url: outputFileURL).tracks(withMediaType: AVMediaType.video)[0]
        let (orientation, _): (UIImage.Orientation, Bool) = self.calculateOrientationFromTransform(tempVideoTrack.preferredTransform)
        let croppingRect: CGRect = self.calculateCroppingRect(originalMovieSize: tempVideoTrack.naturalSize, orientation: orientation, previewFrameRect: (self.videoLayer?.bounds)!, fullFrameRect: self.view.bounds)
        
        self.cropMovie(
            sourceURL: outputFileURL,
            destinationURL: reoutputFileURL,
            fileType: AVFileType.mov,
            croppingRect: croppingRect,
            complition: {
                DispatchQueue.main.async {
                    self.isVideoSaved = false
                    self.recordButton.isEnabled = true
                    self.flexibleCaptureDelegate?.didCapture(withFileURL: reoutputFileURL)
                }
        })
        
    }
    
    private func showCameraPreview() {
        let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
        let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
        
        self.captureSession = AVCaptureSession()
        
        // add video input to a capture session
        let videoInput = try! AVCaptureDeviceInput(device: videoDevice!)
        self.captureSession?.addInput(videoInput)
        
        // add audio input to a capture session
        let audioInput = try! AVCaptureDeviceInput(device: audioDevice!)
        self.captureSession?.addInput(audioInput)
        
        // add capture output
        let captureOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
        captureOutput.maxRecordedDuration = CMTimeMake(value: self.maxDuration, timescale: 1)
        self.captureSession?.addOutput(captureOutput)
        
        // preview layer
        self.videoLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        self.videoLayer?.frame = self.getPresetPreviewFrame()
        self.videoLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view.layer.addSublayer(self.videoLayer!)
        
        self.captureSession?.startRunning()
        
        // slider for adjusting camera preview size
        let sliderWidth: CGFloat = self.view.bounds.width * 0.75
        let sliderHeight: CGFloat = 40
        let sliderRect: CGRect = CGRect(x: (self.view.bounds.width - sliderWidth) / 2, y: self.view.bounds.height - 150, width: sliderWidth, height: sliderHeight)
        self.slider.frame = sliderRect
        self.slider.minimumValue = 0.0
        self.slider.maximumValue = 1.0
        self.slider.value = 0.0
        self.slider.addTarget(self, action: #selector(self.onSliderChanged(sender:)), for: .valueChanged)
        self.view.addSubview(self.slider)
        
        // button on slider for wide frame
        self.buttonForWideFrame.frame = CGRect(x: 0, y: 0, width: 45, height: 20)
        self.buttonForWideFrame.center = CGPoint(x: self.slider.frame.minX + (self.slider.frame.maxX - self.slider.frame.minX) * CGFloat(self.boundaries[0]), y: self.slider.center.y - 40)
        self.buttonForWideFrame.setTitle("Wide", for: .normal)
        self.buttonForWideFrame.setTitleColor(UIColor.white, for: .normal)
        self.buttonForWideFrame.setTitleColor(UIColor.lightGray, for: .disabled)
        self.buttonForWideFrame.addTarget(self, action: #selector(self.onClickButtonForWideFrame(sender:)), for: .touchUpInside)
        self.view.addSubview(self.buttonForWideFrame)
        
        // button on slider for square frame
        self.buttonForSquareFrame.frame = CGRect(x: 0, y: 0, width: 60, height: 20)
        self.buttonForSquareFrame.center = CGPoint(x: self.slider.frame.minX + (self.slider.frame.maxX - self.slider.frame.minX) * CGFloat(self.boundaries[1]), y: self.slider.center.y - 40)
        self.buttonForSquareFrame.setTitle("Square", for: .normal)
        self.buttonForSquareFrame.setTitleColor(UIColor.white, for: .normal)
        self.buttonForSquareFrame.setTitleColor(UIColor.lightGray, for: .disabled)
        self.buttonForSquareFrame.addTarget(self, action: #selector(self.onClickButtonForSquareFrame(sender:)), for: .touchUpInside)
        self.view.addSubview(self.buttonForSquareFrame)
        
        // button on slider for full frame
        self.buttonForFullFrame.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        self.buttonForFullFrame.center = CGPoint(x: self.slider.frame.minX + (self.slider.frame.maxX - self.slider.frame.minX) * CGFloat(self.boundaries[2]), y: self.slider.center.y - 40)
        self.buttonForFullFrame.setTitle("Full", for: .normal)
        self.buttonForFullFrame.setTitleColor(UIColor.white, for: .normal)
        self.buttonForFullFrame.setTitleColor(UIColor.lightGray, for: .disabled)
        self.buttonForFullFrame.addTarget(self, action: #selector(self.onClickButtonForFullFrame(sender:)), for: .touchUpInside)
        self.view.addSubview(self.buttonForFullFrame)
        
        // button on slider for tall frame
        self.buttonForTallFrame.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        self.buttonForTallFrame.center = CGPoint(x: self.slider.frame.minX + (self.slider.frame.maxX - self.slider.frame.minX) * CGFloat(self.boundaries[3]), y: self.slider.center.y - 40)
        self.buttonForTallFrame.setTitle("Tall", for: .normal)
        self.buttonForTallFrame.setTitleColor(UIColor.white, for: .normal)
        self.buttonForTallFrame.setTitleColor(UIColor.lightGray, for: .disabled)
        self.buttonForTallFrame.addTarget(self, action: #selector(self.onClickButtonForTallFrame(sender:)), for: .touchUpInside)
        self.view.addSubview(self.buttonForTallFrame)
        
        // record button
        self.recordButton = UIButton(frame: CGRect(x: 0,y: 0,width: 140,height: 50))
        self.recordButton.backgroundColor = UIColor.gray
        self.recordButton.layer.masksToBounds = true
        self.recordButton.setTitle("Record", for: UIControl.State.normal)
        self.recordButton.layer.cornerRadius = 20.0
        self.recordButton.layer.position = CGPoint(x: self.view.bounds.width/2, y:self.view.bounds.height-70)
        self.recordButton.addTarget(self, action: #selector(self.onClickRecordButton(sender:)), for: .touchUpInside)
        self.view.addSubview(self.recordButton)
        
    }
    
    @objc private func onSliderChanged(sender: UISlider) {
        self.videoLayer?.frame = createResizedPreviewFrame(withResizingParameter: slider.value)
    }
    
    @objc private func onClickButtonForWideFrame(sender: UIButton) {
        self.forcePreviewFrameToResize(withResizingParameter: self.boundaries[0])
    }
    
    @objc private func onClickButtonForSquareFrame(sender: UIButton) {
        self.forcePreviewFrameToResize(withResizingParameter: self.boundaries[1])
    }
    
    @objc private func onClickButtonForFullFrame(sender: UIButton) {
        self.forcePreviewFrameToResize(withResizingParameter: self.boundaries[2])
    }
    
    @objc private func onClickButtonForTallFrame(sender: UIButton) {
        self.forcePreviewFrameToResize(withResizingParameter: self.boundaries[3])
    }
    
    @objc private func onClickRecordButton(sender: UIButton) {
        if !isRecording {
            // start recording
            let tempDirectory: URL = URL(fileURLWithPath: NSTemporaryDirectory())
            let tempFileURL: URL = tempDirectory.appendingPathComponent("temp.mov")
            let captureOutput: AVCaptureMovieFileOutput = self.captureSession?.outputs.first as! AVCaptureMovieFileOutput
            captureOutput.startRecording(to: tempFileURL, recordingDelegate: self)
            
            self.slider.isEnabled = false
            self.buttonForFullFrame.isEnabled = false
            self.buttonForSquareFrame.isEnabled = false
            self.buttonForWideFrame.isEnabled = false
            self.buttonForTallFrame.isEnabled = false
            self.isRecording = true
            
            self.changeButtonColor(target: self.recordButton, color: UIColor.red)
            self.recordButton.setTitle("●Recording", for: .normal)
        } else {
            // stop recording
            let captureOutput: AVCaptureMovieFileOutput = self.captureSession?.outputs.first as! AVCaptureMovieFileOutput
            captureOutput.stopRecording()
            self.isRecording = false
            self.buttonForFullFrame.isEnabled = true
            self.buttonForSquareFrame.isEnabled = true
            self.buttonForWideFrame.isEnabled = true
            self.buttonForTallFrame.isEnabled = true
            self.slider.isEnabled = true
            self.changeButtonColor(target: self.recordButton, color: UIColor.gray)
            self.recordButton.setTitle("Record", for: .normal)
            self.recordButton.isEnabled = false
            
            // update preset slider value
            let userDefaults: UserDefaults = UserDefaults.standard
            userDefaults.set(self.slider.value, forKey: "sliderValueForCameraFrame")
            userDefaults.synchronize()
        }
    }
    
    private func getPresetPreviewFrame() -> CGRect {
        return self.view.bounds
    }
    
    private func applyPresetPreviewFrame() {
        let userDefaults: UserDefaults = UserDefaults.standard
        let boundaryForFullFrame: Float = self.boundaries[2]
        userDefaults.register(defaults: ["sliderValueForCameraFrame": boundaryForFullFrame])
        let presetSliderValue: Float = userDefaults.object(forKey: "sliderValueForCameraFrame") as! Float
        self.forcePreviewFrameToResize(withResizingParameter: presetSliderValue)
    }
    
    private func createResizedPreviewFrame(withResizingParameter resizingParameter: Float) -> CGRect {
        guard self.boundaries[0] <= resizingParameter && resizingParameter <= self.boundaries[self.boundaries.count - 1] else {
            return self.view.bounds
        }
        
        let maximumWidth: CGFloat = self.view.bounds.width
        let maximumHeight: CGFloat = self.view.bounds.height
        let minimumWidth: CGFloat = maximumHeight * self.minimumFrameRatio_
        let minimumHeight: CGFloat = maximumWidth * self.minimumFrameRatio_
        let squareWidth: CGFloat = maximumWidth
        let squareHeight: CGFloat = maximumWidth
        
        var resizingCoefficient: Array<CGFloat> = []
        for (i, boundary) in self.boundaries.enumerated() {
            if (i == 0) {
                resizingCoefficient.append(0.0)
            } else {
                resizingCoefficient.append(CGFloat((resizingParameter - self.boundaries[i-1]) / (boundary - self.boundaries[i-1])))
            }
        }
        
        let resultWidth: CGFloat!
        let resultHeight: CGFloat!
        if (resizingParameter < self.boundaries[1]) {
            // wide(maximumWidth x minimumHeight)  --> square
            resultWidth = squareWidth
            resultHeight = minimumHeight + (squareHeight - minimumHeight) * resizingCoefficient[1]
        } else if (resizingParameter <= self.boundaries[2]) {
            // square --> full
            resultWidth = squareWidth + (maximumWidth - squareWidth) * resizingCoefficient[2]
            resultHeight = squareWidth + (maximumHeight - squareHeight) * resizingCoefficient[2]
        } else {
            // full --> tall(minimumHeight x maximumWidth)
            resultWidth = maximumWidth - (maximumWidth - minimumWidth) * resizingCoefficient[3]
            resultHeight = maximumHeight
        }
        let resultX: CGFloat = (maximumWidth - resultWidth) * 0.5
        let resultY: CGFloat = (maximumHeight - resultHeight) * 0.5
        
        let resultRect: CGRect = CGRect(x: resultX, y: resultY, width: resultWidth, height: resultHeight)
        return resultRect
    }
    
    private func forcePreviewFrameToResize(withResizingParameter resizingParameter: Float) {
        self.slider.value = resizingParameter
        self.videoLayer?.frame = createResizedPreviewFrame(withResizingParameter: self.slider.value)
    }
    
    private func changeButtonColor(target: UIButton, color: UIColor) {
        target.backgroundColor = color
    }
    
    private func cropMovie(sourceURL: URL, destinationURL: URL, fileType: AVFileType, croppingRect: CGRect, complition: @escaping () -> Void) {
        self.exportMovie(sourceURL: sourceURL, destinationURL: destinationURL, fileType: fileType, fullFrameRect: self.view.bounds, croppingRect: croppingRect, completion: complition)
    }
    
    private func calculateCroppingRect(originalMovieSize: CGSize, orientation: UIImage.Orientation, previewFrameRect: CGRect, fullFrameRect: CGRect) -> CGRect {
        return self.calculateCroppingRect(movieSize: originalMovieSize, movieOrientation: orientation ,previewFrameRect: previewFrameRect, fullFrameRect: fullFrameRect)
    }
    
    private func showResizingUIs() {
        self.slider.isHidden = false
        self.buttonForFullFrame.isHidden = false
        self.buttonForSquareFrame.isHidden = false
        self.buttonForWideFrame.isHidden = false
        self.buttonForTallFrame.isHidden = false
    }
    
    private func hideResizingUIs() {
        self.slider.isHidden = true
        self.buttonForFullFrame.isHidden = true
        self.buttonForSquareFrame.isHidden = true
        self.buttonForWideFrame.isHidden = true
        self.buttonForTallFrame.isHidden = true
    }
    
}
