# FlexibleAVCapture

[![CI Status](https://img.shields.io/travis/hahnah/FlexibleAVCapture.svg?style=flat)](https://travis-ci.org/hahnah/FlexibleAVCapture)
[![Version](https://img.shields.io/cocoapods/v/FlexibleAVCapture.svg?style=flat)](https://cocoapods.org/pods/FlexibleAVCapture)
[![License](https://img.shields.io/cocoapods/l/FlexibleAVCapture.svg?style=flat)](https://cocoapods.org/pods/FlexibleAVCapture)
[![Platform](https://img.shields.io/cocoapods/p/FlexibleAVCapture.svg?style=flat)](https://cocoapods.org/pods/FlexibleAVCapture)

This pod provides a kind of AV capture view controller with flexible camera frame. It includes default capture settings, preview layer, buttons, tap-gesture focusing, pinch-gesture zooming, and so on.

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

+ Adopt `FlexibleAVCaptureDelegate` protocol and implement `didCapture(withFileURL fileURL: URL)` function.
+ Create an `FlexibleAVCaptureViewController` object and set its `delegate`.

```swift
import UIKit
import FlexibleAVCapture

class ViewController: UIViewController, FlexibleAVCaptureDelegate {
    
    let flexibleAVCaptureVC: FlexibleAVCaptureViewController = FlexibleAVCaptureViewController()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.flexibleAVCaptureVC.delegate = self
        self.present(flexibleAVCaptureVC, animated: true, completion: nil)
    }
    
    func didCapture(withFileURL fileURL: URL) {
        print(fileURL)
    }

}
```

## API

### FlexibleAVCaptureViewController

An object that manages capture settings and a session. It also displays a preview layer and handles user interactions.

|Topics                    |API
|--------------------------|-----------------------------------------------------------------------------------
|Initializing              |`init() -> FlexibleAVCaptureViewController`<br /> Initializes a FlexibleAVCaptureViewController object with back camera.
|                          |`init(cameraPosition: AVCaptureDevice.Position) -> FlexibleAVCaptureViewController`<br /> Initializes a FlexibleAVCaptureViewController object to use back camera or front camera.
|Managing Interactions     |`var delegate: FlexibleAVCaptureDelegate?`<br /> The object that acts as the delegate of the flexible AV capture view.
|Managing Capture Settings |`var allowsResizing: Bool`<br /> A Boolean value that indicates whether users can resize camera frame. Allowing this feature hides a resizing slider and resizing buttons. The default value of this property is **true**.
|                          |`var allowsReversingCamera: Bool`<br /> A Boolean value that indicates whether users can make the camera position reversed. Allowing this feature hides a camera-reversing button. The default value of this property is **true**.
|                          |`var allowsSoundEffect: Bool`<br /> A Boolean value that indicates whether sound effect rings at the beginning and the ending of video recording. The default value of this property is **true**.
|                          |`var cameraPosition: AVCaptureDevice.Position`<br /> The camera position being used to capture video. Back camera will be used by default. (This is a get-only property.)
|                          |`var maximumRecordDuration: CMTime`<br /> The longest duration allowed for the recording. The default value of this property is **invalid**, which indicates no limit.
|                          |`var minimumFrameRatio: CGFloat`<br /> The ratio of the vertical(or horizontal) edge length in the full frame when the wideset(or tallest) frame is applied. The default value of this property is **0.34**.
|                          |`var videoQuality: AVCaptureSession.Preset`<br /> A constant value indicating the quality level or bit rate of the output. The default value of this property is **medium**. (This is a get-only property.)
|                          |`func canSetVideoQuality(_ videoQuality: AVCaptureSession.Preset) -> Bool`<br /> Returns a Boolean value that indicates whether the receiver can use the given preset.
|                          |`func forceResize(withResizingParameter resizingParameter: Float) -> Void`<br /> Recieve a Float value between 0.0 and 1.0 and resize the camera frame using the value.
|                          |`func reverseCameraPosition() -> Void`<br /> Change the camera position to the oppsite of the current position.
|                          |`func setVideoQuality(_ videoQuality: AVCaptureSession.Preset) -> Void`<br /> Change the video capturing quality.
|Replasing Default UI      |`func replaceFullFramingButton(with button: UIButton) -> Void`<br /> Replace the existing full-framing button.
|                          |`func replaceResizingSlider(with slider: UISlider) -> Void`<br /> Replace the existing resizing slider. The slider's range will be forced to be 0.0 to 1.0.
|                          |`func replaceRecordButton(with button: UIButton) -> Void`<br /> Replace the existing record button.
|                          |`func replaceReverseButton(with button: UIButton) -> Void`<br /> Replace the existing camera-position-reversing button.
|                          |`func replaceSquareFramingButton(with button: UIButton) -> Void`<br /> Replace the existing square-framing button.
|                          |`func replaceTallFramingButton(with button: UIButton) -> Void`<br /> Replace the existing tall-framing button.
|                          |`func replaceWideFramingButton(with button: UIButton) -> Void`<br /> Replace the existing wide-framing button.

### FlexibleAVCaptureDelegate

Defines an interface for delegates of FlexibleAVCaptureViewController to respond to events that occur in the process of recording a single file.  
The delegate of an FlexibleAVCaptureViewController object must adopt the FlexibleAVCaptureDelegate protocol.

|Topics           |API
|-----------------|--------------------------------------------------------------
|Delegate Methods |`didCapture(withFileURL fileURL: URL) -> Void`<br /> Informs the delegate when all pending data has been written to an output file. Required.

## Author

hahnah, superhahnah@gmail.com

## License

FlexibleAVCapture is available under the MIT license. See the LICENSE file for more info.
