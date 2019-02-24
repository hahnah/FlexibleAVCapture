# FlexibleAVCapture

[![CI Status](https://img.shields.io/travis/hahnah/FlexibleAVCapture.svg?style=flat)](https://travis-ci.org/hahnah/FlexibleAVCapture)
[![Version](https://img.shields.io/cocoapods/v/FlexibleAVCapture.svg?style=flat)](https://cocoapods.org/pods/FlexibleAVCapture)
[![License](https://img.shields.io/cocoapods/l/FlexibleAVCapture.svg?style=flat)](https://cocoapods.org/pods/FlexibleAVCapture)
[![Platform](https://img.shields.io/cocoapods/p/FlexibleAVCapture.svg?style=flat)](https://cocoapods.org/pods/FlexibleAVCapture)

## Screen Capture

![screencapture](https://raw.githubusercontent.com/hahnah/FlexibleAVCapture/master/screencapture.gif)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Installation

FlexibleAVCapture is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'FlexibleAVCapture'
```

## Usage

Your view controller should satisfy the following conditions:

+ inherit `FlexibleAVCaptureViewControllerDelegate`
+ implement `didCapture(withFileURL fileURL: URL)` function

```swift
import UIKit
import FlexibleAVCapture

class ViewController: UIViewController, FlexibleAVCaptureViewControllerDelegate {
    
    let flexibleAVCaptureVC: FlexibleAVCaptureViewController = FlexibleAVCaptureViewController()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.flexibleAVCaptureVC.flexibleCaptureDelegate = self
        self.present(flexibleAVCaptureVC, animated: true, completion: nil)
    }
    
    func didCapture(withFileURL fileURL: URL) {
        print(fileURL)
    }

}
```

## API

|                          |API
|--------------------------|-----------------------------------------------------------------------------------
|Initializing              |`init() -> FlexibleAVCaptureViewController`<br /> Initializes a FlexibleAVCaptureViewController object with back camera.
|                          |`init(cameraPosition: AVCaptureDevice.Position) -> FlexibleAVCaptureViewController`<br /> Initializes a FlexibleAVCaptureViewController object to use back camera or front camera.
|Managing Interactions     |`var flexibleCaptureDelegate: FlexibleAVCaptureViewControllerDelegate?`<br /> The object that acts as the delegate of the flexible AV capture view.
|Managing Capture Settings |`var allowsResizing: Bool`<br /> A Boolean value that indicates whether users can resize camera frame. Allowing this hides a resizing slider and resizing buttons.
|                          |`var allowsReversingCamera: Bool`<br /> A Boolean value that indicates whether users can make the camera position reversed. Allowing this hides a camera-reversing button.
|                          |`var cameraPosition: AVCaptureDevice.Position`<br /> The camera position being used to capture video. (get only)
|                          |`var maximumRecordDuration: CMTime`<br /> The longest duration allowed for the recording.
|                          |`var minimumFrameRatio: CGFloat`<br /> The percentage of the vertical/horizontal edge length in the full frame when the wideset/tallest frame is applied.
|                          |`var videoQuality: AVCaptureSession.Preset`<br /> A constant value indicating the quality level or bit rate of the output. (get only)
|                          |`func canSetVideoQuality(_ videoQuality: AVCaptureSession.Preset) -> Bool`<br /> Returns a Boolean value that indicates whether the receiver can use the given preset.
|                          |`func forceResize(withResizingParameter resizingParameter: Float) -> Void`<br /> Recieve a Float value between 0.0 and 1.0 and resize the camera frame using the value.
|                          |`func reverseCameraPosition() -> Void`<br /> Change the camera position to the oppsite of the current position.
|                          |`func setVideoQuality(_ videoQuality: AVCaptureSession.Preset) -> Void`<br /> Try to set the video capturing quality.
|Replasing Default UI      |`func replaceFullFramingButton(with button: UIButton) -> Void`<br /> Replace the existing full-framing button.
|                          |`func replaceResizingSlider(with slider: UISlider) -> Void`<br /> Replace the existing resizing slider. The slider's range will be forced to be 0.0 to 1.0.
|                          |`func replaceRecordButton(with button: UIButton) -> Void`<br /> Replace the existing record button.
|                          |`func replaceReverseButton(with button: UIButton) -> Void`<br /> Replace the existing camera-position-reversing button.
|                          |`func replaceSquareFramingButton(with button: UIButton) -> Void`<br /> Replace the existing square-framing button.
|                          |`func replaceTallFramingButton(with button: UIButton) -> Void`<br /> Replace the existing tall-framing button.
|                          |`func replaceWideFramingButton(with button: UIButton) -> Void`<br /> Replace the existing wide-framing button.

## Author

hahnah, superhahnah@gmail.com

## License

FlexibleAVCapture is available under the MIT license. See the LICENSE file for more info.
