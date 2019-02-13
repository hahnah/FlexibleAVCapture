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
    public var maxDuration: CMTime = CMTimeMake(value: 60, timescale: 1)
    public var cameraPosition: AVCaptureDevice.Position {
        get {
            return self.cameraPosition_
        }
    }
    public var videoQuality: AVCaptureSession.Preset {
        get {
            return self.videoQuality_
        }
    }
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
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        self.cameraPosition_ = .back
        self.setupCaptureSession(withPosition: self.cameraPosition, withQuality: self.videoQuality)
    }
    
    public init(cameraPosition: AVCaptureDevice.Position) {
        super.init(nibName: nil, bundle: nil)
        self.cameraPosition_ = cameraPosition
        self.setupCaptureSession(withPosition: self.cameraPosition, withQuality: self.videoQuality)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func reverseCameraPosition() {
        guard let captureOutput: AVCaptureMovieFileOutput = self.captureSession?.outputs.first as? AVCaptureMovieFileOutput else {
            debugPrint("Failed to reverseCameraPosition because there is no capture session's output.")
            return
        }
        guard !captureOutput.isRecording else {
            debugPrint("Failed to reverseCameraPosition because the recording still working.")
            return
        }
        
        self.saveSliderValue()

        self.captureSession?.stopRunning()
        self.captureSession?.inputs.forEach { input in
            self.captureSession?.removeInput(input)
        }
        self.captureSession?.outputs.forEach { output in
            self.captureSession?.removeOutput(output)
        }
        
        self.cameraPosition_ = self.cameraPosition == .front ? .back : .front
        
        // prepare new capture session preview with opposite camera
        let newCameraPosition: AVCaptureDevice.Position = self.videoDevice?.position == .front ? .back : .front
        self.setupCaptureSession(withPosition: newCameraPosition, withQuality: self.videoQuality)
        let newVideoLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
        newVideoLayer.frame = self.view.bounds
        newVideoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        // horizontal flip
        UIView.transition(with: self.view, duration: 1.0, options: [.transitionFlipFromLeft], animations: nil, completion: { _ in
            // replace camera preview with new one
            self.view.layer.replaceSublayer(self.previewLayer!, with: newVideoLayer)
            self.cameraPosition_ = newCameraPosition
            self.previewLayer = newVideoLayer
            self.applyPresetPreviewFrame()
        })
    }
    
    public func canSetVideoQuality(_ videoQuality: AVCaptureSession.Preset) -> Bool {
        guard !((self.captureSession?.outputs.first as? AVCaptureMovieFileOutput)?.isRecording ?? true) else {
            return false
        }
        var result: Bool = false
        self.captureSession?.beginConfiguration()
        if self.captureSession?.canSetSessionPreset(videoQuality) ?? false {
            result = true
        } else {
            result = false
        }
        self.captureSession?.commitConfiguration()
        return result
    }
    
    public func setVideoQuality(_ videoQuality: AVCaptureSession.Preset) {
        guard !((self.captureSession?.outputs.first as? AVCaptureMovieFileOutput)?.isRecording ?? true)  else {
            debugPrint("Failed to setVideoQuality, because the capture session is still running or there is no capture session.")
            return
        }
        self.captureSession?.beginConfiguration()
        if self.captureSession?.canSetSessionPreset(videoQuality) ?? false {
            self.captureSession?.sessionPreset = videoQuality
            self.videoQuality_ = videoQuality
        } else {
            debugPrint("Failed to set videoQuality to " + videoQuality.rawValue + ".")
        }
        self.captureSession?.commitConfiguration()
    }
    
    private var cameraPosition_: AVCaptureDevice.Position = .back
    private var minimumFrameRatio_: CGFloat = 0.34
    private var allowResizing_: Bool = true
    private var videoQuality_: AVCaptureSession.Preset = .medium
    
    private var captureSession: AVCaptureSession? = nil
    private var videoDevice: AVCaptureDevice?
    
    private var baseZoomFanctor: CGFloat = 1.0
    private var previewLayer: AVCaptureVideoPreviewLayer? = nil
    private var slider: UISlider = UISlider()
    private var buttonForFullFrame: UIButton = UIButton()
    private var buttonForSquareFrame: UIButton = UIButton()
    private var buttonForWideFrame: UIButton = UIButton()
    private var buttonForTallFrame: UIButton = UIButton()
    private var recordButton: UIButton = UIButton()
    private var reverseButton: UIButton = UIButton()
    private var isVideoSaved: Bool = false
    private let boundaries: Array<Float> = [0.0,
                                    1.0 / 3.0,
                                    2.0 / 3.0,
                                    1.0]
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        self.view.backgroundColor = UIColor.black
        self.setupPreviewLayer()
        self.setupOperatableUIs()
        self.applyPresetPreviewFrame()
        self.setupPinchGestureRecognizer()
        self.setupTapGestureRecognizer()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        self.captureSession?.stopRunning()
        self.captureSession?.inputs.forEach { input in
            self.captureSession?.removeInput(input)
        }
        self.captureSession?.outputs.forEach { output in
            self.captureSession?.removeOutput(output)
        }
    }
    
    public func forceResize(withResizingParameter resizingParameter: Float) {
        guard 0 <= resizingParameter && resizingParameter <= 1.0 else {
            debugPrint("Illegal parameter in forceResize. withResizingParameter should fulill the condition 0 ≦ withResizingParameter ≦ 1.")
            return
        }
        self.forcePreviewFrameToResize(withResizingParameter: resizingParameter)
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        /* NOTE: For better response of "Record" button's changing to "●Recording", do not call these two functions here:
         *         - self.updateRecordButton(enableStartRecording: false)
         *         - self.disableResizingUIs()
         */
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        let tempDirectory: URL = URL(fileURLWithPath: NSTemporaryDirectory())
        let reoutputFileURL: URL = tempDirectory.appendingPathComponent("mytemp.mov")
        
        let tempVideoTrack: AVAssetTrack = AVAsset(url: outputFileURL).tracks(withMediaType: AVMediaType.video)[0]
        let (orientation, _): (UIImage.Orientation, Bool) = self.calculateOrientationFromTransform(tempVideoTrack.preferredTransform)
        let croppingRect: CGRect = self.calculateCroppingRect(originalMovieSize: tempVideoTrack.naturalSize, orientation: orientation, previewFrameRect: (self.previewLayer?.bounds)!, fullFrameRect: self.view.bounds)
        
        self.cropMovie(
            sourceURL: outputFileURL,
            destinationURL: reoutputFileURL,
            fileType: AVFileType.mov,
            croppingRect: croppingRect,
            complition: {
                DispatchQueue.main.async {
                    self.isVideoSaved = false
                    self.updateRecordButton(enableStartRecording: true)
                    self.recordButton.isEnabled = true
                    self.enableOperatableUIs()
                    self.saveSliderValue()
                    self.flexibleCaptureDelegate?.didCapture(withFileURL: reoutputFileURL)
                }
        })
        
    }
    
    private func setupCaptureSession(withPosition cameraPosition: AVCaptureDevice.Position, withQuality videoQuality: AVCaptureSession.Preset) {
        self.videoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: cameraPosition)
        let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
        
        self.captureSession = AVCaptureSession()
        
        // add video input to a capture session
        let videoInput = try! AVCaptureDeviceInput(device: self.videoDevice!)
        self.captureSession?.addInput(videoInput)
        
        // add audio input to a capture session
        let audioInput = try! AVCaptureDeviceInput(device: audioDevice!)
        self.captureSession?.addInput(audioInput)
        
        // add capture output
        let captureOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
        captureOutput.maxRecordedDuration = self.maxDuration
        self.captureSession?.addOutput(captureOutput)
        
        // video quality setting
        if self.canSetVideoQuality(videoQuality) {
            self.setVideoQuality(videoQuality)
        }
        
        self.captureSession?.startRunning()
    }
    
    private func setupPreviewLayer() {
        // preview layer
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        self.previewLayer?.frame = self.getPresetPreviewFrame()
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer!)
    }
    
    private func setupOperatableUIs() {
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
        self.buttonForWideFrame.frame = CGRect(x: 0, y: 0, width: 45, height: 30)
        self.buttonForWideFrame.center = CGPoint(x: self.slider.frame.minX + (self.slider.frame.maxX - self.slider.frame.minX) * CGFloat(self.boundaries[0]), y: self.slider.center.y - 40)
        self.buttonForWideFrame.setTitle("Wide", for: .normal)
        self.buttonForWideFrame.setTitleColor(UIColor.white, for: .normal)
        self.buttonForWideFrame.setTitleColor(UIColor.lightGray, for: .disabled)
        self.buttonForWideFrame.addTarget(self, action: #selector(self.onTapButtonForWideFrame(sender:)), for: .touchUpInside)
        self.view.addSubview(self.buttonForWideFrame)
        
        // button on slider for square frame
        self.buttonForSquareFrame.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        self.buttonForSquareFrame.center = CGPoint(x: self.slider.frame.minX + (self.slider.frame.maxX - self.slider.frame.minX) * CGFloat(self.boundaries[1]), y: self.slider.center.y - 40)
        self.buttonForSquareFrame.setTitle("Square", for: .normal)
        self.buttonForSquareFrame.setTitleColor(UIColor.white, for: .normal)
        self.buttonForSquareFrame.setTitleColor(UIColor.lightGray, for: .disabled)
        self.buttonForSquareFrame.addTarget(self, action: #selector(self.onTapButtonForSquareFrame(sender:)), for: .touchUpInside)
        self.view.addSubview(self.buttonForSquareFrame)
        
        // button on slider for full frame
        self.buttonForFullFrame.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
        self.buttonForFullFrame.center = CGPoint(x: self.slider.frame.minX + (self.slider.frame.maxX - self.slider.frame.minX) * CGFloat(self.boundaries[2]), y: self.slider.center.y - 40)
        self.buttonForFullFrame.setTitle("Full", for: .normal)
        self.buttonForFullFrame.setTitleColor(UIColor.white, for: .normal)
        self.buttonForFullFrame.setTitleColor(UIColor.lightGray, for: .disabled)
        self.buttonForFullFrame.addTarget(self, action: #selector(self.onTapButtonForFullFrame(sender:)), for: .touchUpInside)
        self.view.addSubview(self.buttonForFullFrame)
        
        // button on slider for tall frame
        self.buttonForTallFrame.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
        self.buttonForTallFrame.center = CGPoint(x: self.slider.frame.minX + (self.slider.frame.maxX - self.slider.frame.minX) * CGFloat(self.boundaries[3]), y: self.slider.center.y - 40)
        self.buttonForTallFrame.setTitle("Tall", for: .normal)
        self.buttonForTallFrame.setTitleColor(UIColor.white, for: .normal)
        self.buttonForTallFrame.setTitleColor(UIColor.lightGray, for: .disabled)
        self.buttonForTallFrame.addTarget(self, action: #selector(self.onTapButtonForTallFrame(sender:)), for: .touchUpInside)
        self.view.addSubview(self.buttonForTallFrame)
        
        // record button
        self.recordButton.frame = CGRect(x: 0, y: 0, width: 140, height: 50)
        self.recordButton.backgroundColor = UIColor.gray
        self.recordButton.layer.masksToBounds = true
        self.recordButton.setTitle("Record", for: UIControl.State.normal)
        self.recordButton.layer.cornerRadius = 20.0
        self.recordButton.layer.position = CGPoint(x: self.view.bounds.width * 0.5, y:self.view.bounds.height - 70)
        self.recordButton.addTarget(self, action: #selector(self.onTapRecordButton(sender:)), for: .touchUpInside)
        self.view.addSubview(self.recordButton)
        
        // camera-reversing button
        self.reverseButton.frame = CGRect(x: 0, y: 0, width: 50, height: 40)
        self.reverseButton.center = CGPoint(x: self.view.bounds.width - self.reverseButton.frame.width, y: self.view.bounds.height - 70)
        self.reverseButton.backgroundColor = UIColor.clear
        self.reverseButton.setTitle("Reverse", for: .normal)
        self.reverseButton.setTitleColor(UIColor.white, for: .normal)
        self.reverseButton.setTitleColor(UIColor.lightGray, for: .disabled)
        self.reverseButton.addTarget(self, action: #selector(self.onTapReverseButton(sender:)), for: .touchUpInside)
        self.view.addSubview(self.reverseButton)
    }
    
    private func setupPinchGestureRecognizer() {
        // pinch recognizer for zooming
        let pinchGestureRecognizer: UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.onPinchGesture(_:)))
        self.view.addGestureRecognizer(pinchGestureRecognizer)
    }
    
    private func setupTapGestureRecognizer() {
        // tap recognizer for focusing
        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onTapGesture(_:)))
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func onSliderChanged(sender: UISlider) {
        self.previewLayer?.frame = createResizedPreviewFrame(withResizingParameter: slider.value)
    }
    
    @objc private func onTapButtonForWideFrame(sender: UIButton) {
        self.forcePreviewFrameToResize(withResizingParameter: self.boundaries[0])
    }
    
    @objc private func onTapButtonForSquareFrame(sender: UIButton) {
        self.forcePreviewFrameToResize(withResizingParameter: self.boundaries[1])
    }
    
    @objc private func onTapButtonForFullFrame(sender: UIButton) {
        self.forcePreviewFrameToResize(withResizingParameter: self.boundaries[2])
    }
    
    @objc private func onTapButtonForTallFrame(sender: UIButton) {
        self.forcePreviewFrameToResize(withResizingParameter: self.boundaries[3])
    }
    
    @objc private func onPinchGesture(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            self.baseZoomFanctor = (self.videoDevice?.videoZoomFactor)!
        }
        
        let tempZoomFactor: CGFloat = self.baseZoomFanctor * sender.scale
        let newZoomFactdor: CGFloat
        if tempZoomFactor < (self.videoDevice?.minAvailableVideoZoomFactor)! {
            newZoomFactdor = (self.videoDevice?.minAvailableVideoZoomFactor)!
        } else if (self.videoDevice?.maxAvailableVideoZoomFactor)! < tempZoomFactor {
            newZoomFactdor = (self.videoDevice?.maxAvailableVideoZoomFactor)!
        } else {
            newZoomFactdor = tempZoomFactor
        }
        
        do {
            try self.videoDevice?.lockForConfiguration()
            self.videoDevice?.ramp(toVideoZoomFactor: newZoomFactdor, withRate: 32.0)
            self.videoDevice?.unlockForConfiguration()
        } catch {
            print("Failed to change zoom factor.")
        }
    }
    
    @objc private func onTapGesture(_ sender: UITapGestureRecognizer) {
        let tapCGPoint = sender.location(ofTouch: 0, in: sender.view)
        let focusView: UIView = UIView()
        focusView.frame.size = CGSize(width: 120, height: 120)
        focusView.center = tapCGPoint
        focusView.backgroundColor = UIColor.white.withAlphaComponent(0)
        focusView.layer.borderColor = UIColor.white.cgColor
        focusView.layer.borderWidth = 2
        focusView.alpha = 1
        sender.view?.addSubview(focusView)
        
        UIView.animate(withDuration: 0.5, animations: {
            focusView.frame.size = CGSize(width: 80, height: 80)
            focusView.center = tapCGPoint
        }, completion: { Void in
            UIView.animate(withDuration: 0.5, animations: {
                focusView.alpha = 0
                }, completion: { Void in
                    focusView.removeFromSuperview()
            })
        })
        
        self.focusWithMode(focusMode: .autoFocus, exposeWithMode: .autoExpose, atDevicePoint: tapCGPoint, motiorSubjectAreaChange: true)
    }
    
    @objc private func onTapRecordButton(sender: UIButton) {
        guard let captureOutput: AVCaptureMovieFileOutput = self.captureSession?.outputs.first as? AVCaptureMovieFileOutput else {
            return
        }
        
        if captureOutput.isRecording {
            // stop recording
            captureOutput.stopRecording()
        } else {
            // start recording
            let tempDirectory: URL = URL(fileURLWithPath: NSTemporaryDirectory())
            let tempFileURL: URL = tempDirectory.appendingPathComponent("temp.mov")
            captureOutput.startRecording(to: tempFileURL, recordingDelegate: self)
            
            self.updateRecordButton(enableStartRecording: false)
            self.disableOperatableUIs()
        }
    }
    
    @objc private func onTapReverseButton(sender: UIButton) {
        self.reverseCameraPosition()
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
        self.previewLayer?.frame = createResizedPreviewFrame(withResizingParameter: self.slider.value)
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
    
    private func enableOperatableUIs() {
        self.buttonForFullFrame.isEnabled = true
        self.buttonForSquareFrame.isEnabled = true
        self.buttonForWideFrame.isEnabled = true
        self.buttonForTallFrame.isEnabled = true
        self.slider.isEnabled = true
        self.reverseButton.isEnabled = true
    }
    
    private func disableOperatableUIs() {
        self.slider.isEnabled = false
        self.buttonForFullFrame.isEnabled = false
        self.buttonForSquareFrame.isEnabled = false
        self.buttonForWideFrame.isEnabled = false
        self.buttonForTallFrame.isEnabled = false
        self.reverseButton.isEnabled = false
    }
    
    private func updateRecordButton(enableStartRecording: Bool) {
        if enableStartRecording {
            self.changeButtonColor(target: self.recordButton, color: UIColor.gray)
            self.recordButton.setTitle("Record", for: .normal)
            self.recordButton.isEnabled = false // to prevent restarting recording until fileoutput finish
        } else {
            self.changeButtonColor(target: self.recordButton, color: UIColor.red)
            self.recordButton.setTitle("●Recording", for: .normal)
        }
    }
    
    private func saveSliderValue() {
        let userDefaults: UserDefaults = UserDefaults.standard
        userDefaults.set(self.slider.value, forKey: "sliderValueForCameraFrame")
        userDefaults.synchronize()
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
    
    private func focusWithMode(focusMode : AVCaptureDevice.FocusMode, exposeWithMode expusureMode :AVCaptureDevice.ExposureMode, atDevicePoint point:CGPoint, motiorSubjectAreaChange monitorSubjectAreaChange:Bool) {
            let device : AVCaptureDevice = self.videoDevice!
        do {
            try device.lockForConfiguration()
            if(device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode)){
                device.focusPointOfInterest = point
                device.focusMode = focusMode
            }
            if(device.isExposurePointOfInterestSupported && device.isExposureModeSupported(expusureMode)){
                device.exposurePointOfInterest = point
                device.exposureMode = expusureMode
            }
            
            device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
            device.unlockForConfiguration()
            
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
}
