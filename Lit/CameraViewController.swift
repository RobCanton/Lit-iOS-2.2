//
//  CameraViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-06.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import AVFoundation
import RecordButton
import Firebase


enum CameraState {
    case Initiating, Running, PhotoTaken, VideoTaken, Recording
}

enum CameraMode {
    case Front, Back
}

enum FlashMode {
    case Off, On, Auto
}

protocol PopUpProtocolDelegate {
    func close(uploadTask:FIRStorageUploadTask, outputUrl:NSURL?)
}

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, AVCaptureFileOutputRecordingDelegate {
    
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoPlayer: AVPlayer = AVPlayer()
    var playerLayer: AVPlayerLayer?
    var videoUrl: NSURL?
    var cameraDevice: AVCaptureDevice?
    var delegate:PopUpProtocolDelegate?
    
    var flashMode:FlashMode = .Off
    var cameraMode:CameraMode = .Back
    
    var progressTimer : NSTimer!
    var progress : CGFloat! = 0
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    var cameraState:CameraState = .Initiating
        {
        didSet {
            switch cameraState {
            case .Initiating:
                cancelButton.enabled = false
                cancelButton.hidden = true
                sendButton.enabled = false
                sendButton.hidden = true
                break
            case .Running:
                imageView.image = nil
                imageView.hidden = true
                recordButton.buttonState = .Idle
                cancelButton.enabled = false
                cancelButton.hidden = true
                sendButton.enabled = false
                sendButton.hidden = true
                flashButton.enabled = true
                flashButton.hidden = false
                flipButton.enabled = true
                flipButton.hidden = false
                break
            case .PhotoTaken:
                resetProgress()
                imageView.hidden = false
                videoLayer.hidden = true
                recordButton.buttonState = .Idle
                recordButton.buttonState = .Hidden
                cancelButton.enabled = true
                cancelButton.hidden = false
                sendButton.enabled = true
                sendButton.hidden = false
                flashButton.enabled = false
                flashButton.hidden = true
                flipButton.enabled = false
                flipButton.hidden = true
                break
            case .VideoTaken:
                resetProgress()
                imageView.hidden = true
                videoLayer.hidden = false
                recordButton.buttonState = .Idle
                recordButton.buttonState = .Hidden
                cancelButton.enabled = true
                cancelButton.hidden = false
                sendButton.enabled = true
                sendButton.hidden = false
                flashButton.enabled = false
                flashButton.hidden = true
                flipButton.enabled = false
                flipButton.hidden = true
                break
            case .Recording:
                flashButton.enabled = false
                flashButton.hidden = true
                flipButton.enabled = false
                flipButton.hidden = true
                break
            default:
                break
            }
        }
    }
    
    @IBOutlet weak var videoLayer: UIView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var snapButton: UIButton!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBAction func cancelButtonTapped(sender: UIButton) {
        
        playerLayer?.player?.seekToTime(CMTimeMake(0, 1))
        playerLayer?.player?.pause()
        
        playerLayer?.removeFromSuperlayer()
        videoUrl = nil
        
        cameraState = .Running
    }
    @IBOutlet weak var sendButton: UIButton!
    
    @IBAction func sendButtonTapped(sender: UIButton) {
        if cameraState == .PhotoTaken {
            if let image = imageView.image {
                self.imageView.hidden = true
                print("Sending dat image")
                if let uploadTask = FirebaseService.sendImage(image)
                {
                    self.delegate?.close(uploadTask, outputUrl: nil)
                }
            }
        }
        else if cameraState == .VideoTaken {
            playerLayer?.player?.seekToTime(CMTimeMake(0, 1))
            playerLayer?.player?.pause()
            
            playerLayer?.removeFromSuperlayer()
            videoLayer.hidden = true
            
            print("Send tapped video taken")
            
            if let url = videoUrl {
                
                let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                let outputUrl = documentsURL.URLByAppendingPathComponent("output.mp4")
                
                FirebaseService.compressVideo(url, outputURL: outputUrl, handler: { session in
                    print("here: \(session.status)")
                    /*
                    T0D0 - HANDLE COMPRESSION ERRORS
                    */
                    dispatch_async(dispatch_get_main_queue(), {
                        if let uploadTask = FirebaseService.uploadVideo(outputUrl) {
                            self.videoUrl = nil
                            self.delegate?.close(uploadTask, outputUrl: outputUrl)
                        }
                    })
                })
            }
        }
        
        cameraState = .Running
    }

    var recordButton: RecordButton!
    var flashButton: UIButton!
    var flipButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraView.frame = self.view.frame
        
        recordButton = RecordButton(frame: CGRectMake(0,0,70,70))
        
        recordButton.center = self.snapButton.center
        recordButton.buttonColor = UIColor(white: 1.0, alpha: 0.6)
        
        recordButton.progressColor = .redColor()
        recordButton.closeWhenFinished = false
        recordButton.center.x = self.view.center.x
        
        view.addSubview(recordButton)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tapped:")
        recordButton.addGestureRecognizer(tapGestureRecognizer)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "longPressed:")
        recordButton.addGestureRecognizer(longPressRecognizer)
        
        flashButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        flashButton.setImage(UIImage(named: "flashoff"), forState: .Normal)
        flashButton.center = CGPoint(x: (recordButton.center.x / 2) - flashButton.frame.width / 8, y: recordButton.center.y)
        flashButton.addTarget(self, action: #selector(switchFlashMode), forControlEvents: .TouchUpInside)
        self.view.addSubview(flashButton)
        
        flipButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        flipButton.setImage(UIImage(named: "switchcamera"), forState: .Normal)
        flipButton.center = CGPoint(x: (recordButton.center.x + recordButton.center.x / 2) + flipButton.frame.width / 8, y: recordButton.center.y)
        flipButton.addTarget(self, action: #selector(switchCamera), forControlEvents: .TouchUpInside)
        self.view.addSubview(flipButton)
        
        reloadCamera()
    }
    
    func reloadCamera() {
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
        
        let captureTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "AutoFocusGesture:")
        captureTapGesture.numberOfTapsRequired = 1
        captureTapGesture.numberOfTouchesRequired = 1
        self.cameraView.addGestureRecognizer(captureTapGesture)
        
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
                    previewLayer?.frame = cameraView.bounds
                    cameraView.layer.addSublayer(previewLayer!)
                    captureSession?.startRunning()
                    cameraState = .Running
                }
            }
            
        } catch let error as NSError {
            print(error)
        }
    }
    
    func switchFlashMode(sender:UIButton!) {
        if let avDevice = cameraDevice
        {
            // check if the device has torch
            if avDevice.hasTorch {
                // lock your device for configuration
                do {
                    _ = try avDevice.lockForConfiguration()
                } catch {
                    print("aaaa")
                }
                switch flashMode {
                case .On:
                    
                    avDevice.flashMode = .Auto
                    flashMode = .Auto
                    flashButton.setImage(UIImage(named: "flashauto"), forState: .Normal)
                    break
                case .Auto:
                    avDevice.flashMode = .Off
                    flashMode = .Off
                    flashButton.setImage(UIImage(named: "flashoff"), forState: .Normal)
                    break
                case .Off:
                    avDevice.flashMode = .On
                    flashMode = .On
                    flashButton.setImage(UIImage(named: "flashon"), forState: .Normal)
                    break
                }
                // unlock your device
                avDevice.unlockForConfiguration()
            }
        }
        
    }
    
    func switchCamera(sender:UIButton!) {
        switch cameraMode {
        case .Back:
            cameraMode = .Front
            break
        case .Front:
            cameraMode = .Back
            break
        }
        reloadCamera()
    }
    
    func updateProgress() {
        
        let maxDuration = CGFloat(10) // Max duration of the recordButton
        
        progress = progress + (CGFloat(0.05) / maxDuration)
        recordButton.setProgress(progress)
        
        if progress >= 1 {
            progressTimer.invalidate()
        }
        
    }
    
    func resetProgress() {
        progress = 0
        recordButton.setProgress(progress)
    }
    
    
    func tapped(sender: UITapGestureRecognizer)
    {
        print("wut")
        didPressTakePhoto()
    }
    
    func longPressed(sender: UILongPressGestureRecognizer)
    {
        switch sender.state {
        case .Began:
            if cameraState == .Running {
                recordVideo()
            }
            break
        case .Ended:
            if cameraState == .Recording {
                videoFileOutput?.stopRecording()
            }
            break
        default:
            break
        }
    }
    
    var didTakePhoto = Bool()
    
    func didPressTakePhoto()
    {
        cameraState = .PhotoTaken
        self.imageView.image = nil
        AudioServicesPlayAlertSound(1108)
        if let videoConnection = stillImageOutput?.connectionWithMediaType(AVMediaTypeVideo)
        {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler:{
                (sampleBuffer, error) in
                
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProviderCreateWithCFData(imageData)
                    let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, .RenderingIntentDefault)
                    
                    var image:UIImage!
                    if self.cameraMode == .Front {
                        image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.LeftMirrored)
                    } else {
                        image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
                    }
                    self.imageView.image = image
                }
            })
        }
    }
    
    var animateActivity: Bool!
    func AutoFocusGesture(RecognizeGesture: UITapGestureRecognizer){
        let touchPoint: CGPoint = RecognizeGesture.locationInView(self.cameraView)
        //GET PREVIEW LAYER POINT
        let convertedPoint = self.previewLayer!.captureDevicePointOfInterestForPoint(touchPoint)
        
        //Assign Auto Focus and Auto Exposour
        if let device = cameraDevice {
            do {
                try! device.lockForConfiguration()
                if device.focusPointOfInterestSupported{
                    //Add Focus on Point
                    device.focusPointOfInterest = convertedPoint
                    device.focusMode = AVCaptureFocusMode.AutoFocus
                }
                
                if device.exposurePointOfInterestSupported{
                    //Add Exposure on Point
                    device.exposurePointOfInterest = convertedPoint
                    device.exposureMode = AVCaptureExposureMode.AutoExpose
                }
                device.unlockForConfiguration()
            }
        }
    }
    
    var videoFileOutput: AVCaptureMovieFileOutput?
    func recordVideo() {
        cameraState = .Recording
        progressTimer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "updateProgress", userInfo: nil, repeats: true)
        
        let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self
    
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let filePath = documentsURL.URLByAppendingPathComponent("temp.mp4")
        
        // Do recording and save the output to the `filePath`
        videoFileOutput!.startRecordingToOutputFileURL(filePath, recordingDelegate: recordingDelegate)
    }
    
    
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        cameraState = .VideoTaken
        progressTimer.invalidate()
        videoUrl = outputFileURL

        let item = AVPlayerItem(URL: outputFileURL)
        videoPlayer.replaceCurrentItemWithPlayerItem(item)
        playerLayer = AVPlayerLayer(player: videoPlayer)
        
        playerLayer!.frame = self.view.bounds
        self.videoLayer.layer.addSublayer(playerLayer!)
        
        playerLayer!.player?.play()
        playerLayer!.player?.actionAtItemEnd = .None
        loopVideo(playerLayer!.player!)
        
        return
    }
    
    func loopVideo(videoPlayer: AVPlayer) {
        NSNotificationCenter.defaultCenter().addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: nil, queue: nil) { notification in
            videoPlayer.seekToTime(kCMTimeZero)
            videoPlayer.play()
        }
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        print("Started recording")
        cameraState = .Recording
        return
    }
    
}