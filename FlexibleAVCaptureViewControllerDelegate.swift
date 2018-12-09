import UIKit
import AVKit

extension FlexibleAVCaptureViewController: UIVideoEditorControllerDelegate, UINavigationControllerDelegate {
    
    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        if self.isVideoSaved {
            return
        } else {
            self.isVideoSaved = true
        }
        
        let tmpMovieURL: URL = URL(fileURLWithPath: editedVideoPath)
        let capturingPoint: Float64 = 0 // capturingPoint ∈ [0,1]
        let capturingTime: CMTime = self.generateCMTime(movieURL: tmpMovieURL, capturingPoint: capturingPoint)
        let capturedImage: CGImage? = self.captureImage(movieURL: tmpMovieURL, capturingTime: capturingTime)
        let image: UIImage = UIImage(cgImage: capturedImage!)
        let transform: CGAffineTransform = calculateTransform(mediaURL: tmpMovieURL)
        let uiThumbnail: UIImage = self.generateThumbnail(sourceImage: image, objectiveEdgeLength: self.view.frame.width / 2)
        let cgThumbnail: CGImage = uiThumbnail.cgImage!
        let (orientation, _): (UIImageOrientation, Bool) = calculateOrientationFromTransform(transform)
        let orientationAsString = Content.convertOrientationToString(orientation: orientation)
        
        let newContent: Content = Content.create()
        newContent.saveAsNew(image: capturedImage!, thumbnail: cgThumbnail, orientationAsString: orientationAsString)
        
        let documentsDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let savingURL: URL = documentsDirectory.appendingPathComponent(newContent.movieFileName + newContent.movieFileTypeAsString)
        let typeMov: AVFileType = AVFileType.mov
        
        self.exportMovie(sourceURL: tmpMovieURL, destinationURL: savingURL, fileType: typeMov)
        
        editor.dismiss(animated: true, completion: {
            self.captureSession?.stopRunning()
            self.captureSession?.outputs.forEach({ (captureOutput) in
                self.captureSession?.removeOutput(captureOutput)
            })
            self.captureSession?.inputs.forEach({ (captureInput) in
                self.captureSession?.removeInput(captureInput)
            })
            self.dismiss(animated: true, completion: nil)
        })
        
    }
    
    func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
        editor.dismiss(animated: true, completion: nil)
    }
    
}
