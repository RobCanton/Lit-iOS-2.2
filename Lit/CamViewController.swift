//
//  CamViewController.swift
//  
//
//  Created by Robert Canton on 2016-08-17.
//
//

import UIKit
import AVFoundation
import RecordButton
import Firebase


enum CameraState {
    case Initiating
    case Running
    case PhotoTaken
    case Recording
    case VideoTaken
}

enum FlashMode {
    case Auto, On, Off
}

enum CameraMode {
    case Front, Back
}

class CamViewController: UIViewController {

    
    @IBOutlet weak var cameraView: UIView!
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoPlayer: AVPlayer = AVPlayer()
    var playerLayer: AVPlayerLayer?
    var videoUrl: NSURL?
    var videoFileOutput: AVCaptureMovieFileOutput?
    var cameraDevice: AVCaptureDevice?
    var delegate:PopUpProtocolDelegate?
    
    var flashMode:FlashMode = .Off
    var cameraMode:CameraMode = .Back
    
    var cameraState:CameraState = .Initiating
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("frame: \(view.frame) | cam: \(cameraView.frame)")
        
        reloadCamera()
    }

    
    func reloadCamera() {
        cameraView.backgroundColor = UIColor.redColor()
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPreset1280x720
        
        if cameraMode == .Front
        {
            let videoDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
            
            for device in videoDevices{
                if let device = device as? AVCaptureDevice
                {
                    if device.position == AVCaptureDevicePosition.Front {
                        cameraDevice = device
                        break
                    }
                }
                
            }
        }
        else
        {
            cameraDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        }
        
//        let captureTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "AutoFocusGesture:")
//        captureTapGesture.numberOfTapsRequired = 1
//        captureTapGesture.numberOfTouchesRequired = 1
//        self.cameraView.addGestureRecognizer(captureTapGesture)
        
        do {
            
            let input = try AVCaptureDeviceInput(device: cameraDevice)
            
            videoFileOutput = AVCaptureMovieFileOutput()
            self.captureSession!.addOutput(videoFileOutput)
            //            let audioDevice: AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
            //            do {
            //                let audioInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            //                self.captureSession!.addInput(audioInput)
            //
            //            } catch {
            //                print("Unable to add audio device to the recording.")
            //            }
            
            if captureSession?.canAddInput(input) != nil {
                captureSession?.addInput(input)
                stillImageOutput = AVCaptureStillImageOutput()
                stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                
                if (captureSession?.canAddOutput(stillImageOutput) != nil) {
                    captureSession?.addOutput(stillImageOutput)
                    
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                    previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
                    previewLayer?.frame = cameraView.frame
                    previewLayer?.bounds = cameraView.bounds
                    previewLayer?.contentsRect = cameraView.frame
                    cameraView.layer.addSublayer(previewLayer!)
                    captureSession?.startRunning()
                    cameraState = .Running
                }
            }
            
        } catch let error as NSError {
            print(error)
        }
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
