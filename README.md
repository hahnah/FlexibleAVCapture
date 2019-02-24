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
|Initializing              |init() -> FlexibleAVCaptureViewController
|                          |init(cameraPosition: AVCaptureDevice.Position) -> FlexibleAVCaptureViewController
|                          |func reverseCameraPosition() -> Void
|Managing capture settings |var allowResizing: Bool
|                          |var allowReversingCamera: Bool
|                          |var cameraPosition: AVCaptureDevice.Position
|                          |var flexibleCaptureDelegate: FlexibleAVCaptureViewControllerDelegate?
|                          |var maxRecordDuration: CMTime
|                          |var minimumFrameRatio: CGFloat
|                          |var videoQuality: AVCaptureSession.Preset
|                          |func canSetVideoQuality(_ videoQuality: AVCaptureSession.Preset) -> Bool
|                          |func forceResize(withResizingParameter resizingParameter: Float) -> Void
|                          |func setVideoQuality(_ videoQuality: AVCaptureSession.Preset) -> Void
|Replasing default UI      |func replaceFullFramingButton(with button: UIButton) -> Void
|                          |func replaceResizingSlider(with slider: UISlider) -> Void
|                          |func replaceRecordButton(with button: UIButton) -> Void
|                          |func replaceReverseButton(with button: UIButton) -> Void
|                          |func replaceSquareFramingButton(with button: UIButton) -> Void
|                          |func replaceTallFramingButton(with button: UIButton) -> Void
|                          |func replaceWideFramingButton(with button: UIButton) -> Void

## Author

hahnah, superhahnah@gmail.com

## License

FlexibleAVCapture is available under the MIT license. See the LICENSE file for more info.
