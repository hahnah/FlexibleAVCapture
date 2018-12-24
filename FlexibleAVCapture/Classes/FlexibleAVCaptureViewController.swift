import UIKit
import AVFoundation
import Photos

public class FlexibleAVCaptureViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    var captureSession: AVCaptureSession? = nil
    var videoLayer: AVCaptureVideoPreviewLayer? = nil
    var slider: UISlider = UISlider()
    var buttonForFullFrame1: UIButton = UIButton()
    var buttonForSquareFrame: UIButton = UIButton()
    var buttonForWideFrame: UIButton = UIButton()
    var buttonForTallFrame: UIButton = UIButton()
    var buttonForFullFrame2: UIButton = UIButton()
    var recordButton: UIButton!
    var isRecording: Bool = false
    
    var isVideoSaved: Bool = false
    
    let boundaries: Array<Float> = [0.0,
                                    1.0 / 3.0,
                                    2.0 / 3.0,
                                    1.0]
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.showCameraPreview()
        self.reflectPresetPreviewFrame()
    }
    
    func reflectPresetPreviewFrame() {
        let userDefaults: UserDefaults = UserDefaults.standard
        let boundaryForFullFrame: Float = self.boundaries[2]
        userDefaults.register(defaults: ["sliderValueForCameraFrame": boundaryForFullFrame])
        let presetSliderValue: Float = userDefaults.object(forKey: "sliderValueForCameraFrame") as! Float
        self.forcePreviewFrameToResize(resizingParameter: presetSliderValue)
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func showCameraPreview() {
        let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
        let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
        
        self.captureSession = AVCaptureSession()
        
        // video inputを capture sessionに追加
        let videoInput = try! AVCaptureDeviceInput(device: videoDevice!)
        self.captureSession?.addInput(videoInput)
        
        // audio inputを capture sessionに追加
        let audioInput = try! AVCaptureDeviceInput(device: audioDevice!)
        self.captureSession?.addInput(audioInput)
        
        // max 60sec
        let captureOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
        captureOutput.maxRecordedDuration = CMTimeMake(60, 1)
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
        self.buttonForFullFrame1.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        self.buttonForFullFrame1.center = CGPoint(x: self.slider.frame.minX + (self.slider.frame.maxX - self.slider.frame.minX) * CGFloat(self.boundaries[2]), y: self.slider.center.y - 40)
        self.buttonForFullFrame1.setTitle("Full", for: .normal)
        self.buttonForFullFrame1.setTitleColor(UIColor.white, for: .normal)
        self.buttonForFullFrame1.setTitleColor(UIColor.lightGray, for: .disabled)
        self.buttonForFullFrame1.addTarget(self, action: #selector(self.onClickButtonForFullFrame(sender:)), for: .touchUpInside)
        self.view.addSubview(self.buttonForFullFrame1)
        
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
        self.recordButton.setTitle("Record", for: UIControlState.normal)
        self.recordButton.layer.cornerRadius = 20.0
        self.recordButton.layer.position = CGPoint(x: self.view.bounds.width/2, y:self.view.bounds.height-70)
        self.recordButton.addTarget(self, action: #selector(self.onClickRecordButton(sender:)), for: .touchUpInside)
        self.view.addSubview(self.recordButton)
        
    }
    
    func getPresetPreviewFrame() -> CGRect {
        return self.view.bounds
    }
    
    @objc func onSliderChanged(sender: UISlider) {
        self.videoLayer?.frame = createResizedPreviewFrame(resizingParameter: slider.value)
    }
    
    func createResizedPreviewFrame(resizingParameter: Float) -> CGRect {
        guard self.boundaries[0] <= resizingParameter && resizingParameter <= self.boundaries[self.boundaries.count - 1] else {
            return self.view.bounds
        }
        
        let maximumWidth: CGFloat = self.view.bounds.width
        let maximumHeight: CGFloat = self.view.bounds.height
        let minimumWidth: CGFloat = maximumHeight * 0.34
        let minimumHeight: CGFloat = maximumWidth * 0.34
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
    
    @objc func onClickButtonForWideFrame(sender: UIButton) {
        self.forcePreviewFrameToResize(resizingParameter: self.boundaries[0])
    }
    
    @objc func onClickButtonForSquareFrame(sender: UIButton) {
        self.forcePreviewFrameToResize(resizingParameter: self.boundaries[1])
    }
    
    @objc func onClickButtonForFullFrame(sender: UIButton) {
        self.forcePreviewFrameToResize(resizingParameter: self.boundaries[2])
    }
    
    @objc func onClickButtonForTallFrame(sender: UIButton) {
        self.forcePreviewFrameToResize(resizingParameter: self.boundaries[3])
    }
    
    func forcePreviewFrameToResize(resizingParameter: Float) {
        self.slider.value = resizingParameter
        self.videoLayer?.frame = createResizedPreviewFrame(resizingParameter: self.slider.value)
    }
    
    @objc func onClickRecordButton(sender: UIButton) {
        if !isRecording {
            // start recording
            let tempDirectory: URL = URL(fileURLWithPath: NSTemporaryDirectory())
            let tempFileURL: URL = tempDirectory.appendingPathComponent("temp.mov")
            let captureOutput: AVCaptureMovieFileOutput = self.captureSession?.outputs.first as! AVCaptureMovieFileOutput
            captureOutput.startRecording(to: tempFileURL, recordingDelegate: self)
            
            self.slider.isEnabled = false
            self.buttonForFullFrame1.isEnabled = false
            self.buttonForSquareFrame.isEnabled = false
            self.buttonForWideFrame.isEnabled = false
            self.buttonForTallFrame.isEnabled = false
            self.buttonForFullFrame2.isEnabled = false
            self.isRecording = true
            
            self.changeButtonColor(target: self.recordButton, color: UIColor.red)
            self.recordButton.setTitle("●Recording", for: .normal)
        } else {
            // stop recording
            let captureOutput: AVCaptureMovieFileOutput = self.captureSession?.outputs.first as! AVCaptureMovieFileOutput
            captureOutput.stopRecording()
            self.isRecording = false
            self.buttonForFullFrame1.isEnabled = true
            self.buttonForSquareFrame.isEnabled = true
            self.buttonForWideFrame.isEnabled = true
            self.buttonForTallFrame.isEnabled = true
            self.buttonForFullFrame2.isEnabled = true
            self.slider.isEnabled = true
            self.changeButtonColor(target: self.recordButton, color: UIColor.gray)
            self.recordButton.setTitle("Record", for: .normal)
            
            // update preset slider value
            let userDefaults: UserDefaults = UserDefaults.standard
            userDefaults.set(self.slider.value, forKey: "sliderValueForCameraFrame")
            userDefaults.synchronize()
        }
    }
    
    func changeButtonColor(target: UIButton, color: UIColor) {
        target.backgroundColor = color
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        let tempDirectory: URL = URL(fileURLWithPath: NSTemporaryDirectory())
        let tempFileURL: URL = tempDirectory.appendingPathComponent("mytemp.mov")
        
        let tmpVideoTrack: AVAssetTrack = AVAsset(url: outputFileURL).tracks(withMediaType: AVMediaType.video)[0]
        let (orientation, _): (UIImageOrientation, Bool) = self.calculateOrientationFromTransform(tmpVideoTrack.preferredTransform)
        let croppingRect: CGRect = self.calculateCroppingRect(originalMovieSize: tmpVideoTrack.naturalSize, orientation: orientation, previewFrameRect: (self.videoLayer?.bounds)!, fullFrameRect: self.view.bounds)
        
        let photoplayEditorViewController: UIVideoEditorController = UIVideoEditorController()
        photoplayEditorViewController.modalTransitionStyle = .crossDissolve
        photoplayEditorViewController.delegate = self
        photoplayEditorViewController.videoPath = self.cropMovie(sourceURL: outputFileURL, destinationURL: tempFileURL, fileType: AVFileType.mov, croppingRect: croppingRect, complition: {
            self.isVideoSaved = false
            self.present(photoplayEditorViewController, animated: true, completion: nil)
        }).path
    }
    
    func cropMovie(sourceURL: URL, destinationURL: URL, fileType: AVFileType, croppingRect: CGRect, complition: @escaping () -> Void) -> URL {
        let sliderValueForFull = self.boundaries[2]
        if self.slider.value == sliderValueForFull {
            Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) {_ in
                complition()
            }
            return sourceURL
        }
        self.exportMovie(sourceURL: sourceURL, destinationURL: destinationURL, fileType: fileType, fullFrameRect: self.view.bounds, croppingRect: croppingRect, completion: complition)
        return destinationURL
    }
    
    func calculateCroppingRect(originalMovieSize: CGSize, orientation: UIImageOrientation, previewFrameRect: CGRect, fullFrameRect: CGRect) -> CGRect {
        return self.calculateCroppingRect(movieSize: originalMovieSize, movieOrientation: orientation ,previewFrameRect: previewFrameRect, fullFrameRect: fullFrameRect)
    }
    
}
