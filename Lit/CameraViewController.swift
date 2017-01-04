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
import SwiftMessages
import MapKit
import CoreLocation



enum CameraState {
    case Initiating, Running, PhotoTaken, VideoTaken, Recording, Sending, Sent
}

enum CameraMode {
    case Front, Back
}

enum FlashMode {
    case Off, On, Auto
}

protocol PopUpProtocolDelegate {
    func close(uploadTask:FIRStorageUploadTask, outputUrl:NSURL?)
    func upload(uploadTask:FIRStorageUploadTask)
    func returnToPreviousSelection()
}

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, AVCaptureFileOutputRecordingDelegate, UploadSelectorDelegate, UITextViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var imageCaptureView: UIImageView!
    @IBOutlet weak var videoLayer: UIView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var dismissBtn: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var flashView: UIView!
    
    
    @IBAction func cancelButtonTapped(sender: UIButton) {
        
        playerLayer?.player?.seekToTime(CMTimeMake(0, 1))
        playerLayer?.player?.pause()
        
        playerLayer?.removeFromSuperlayer()
        videoUrl = nil
        
        recordBtn.hidden = false
        cameraState = .Running
    }

    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoPlayer: AVPlayer = AVPlayer()
    var playerLayer: AVPlayerLayer?
    var videoUrl: NSURL?
    var cameraDevice: AVCaptureDevice?
    var tabBarDelegate:PopUpProtocolDelegate?
    
    var flashMode:FlashMode = .Off
    var cameraMode:CameraMode = .Back
    
    var progressTimer : NSTimer!
    var progress : CGFloat! = 0
    
    var recordBtn:CameraButton!
    
    var uploadCoordinate:CLLocation?
    

    var pinchGesture:UIPinchGestureRecognizer!

    
    var cameraState:CameraState = .Initiating
        {
        didSet {
            switch cameraState {
            case .Initiating:
                cancelButton.enabled    = false
                cancelButton.hidden     = true
                sendButton.enabled      = false
                sendButton.hidden       = true
                
                break
            case .Running:
                imageCaptureView.image  = nil
                imageCaptureView.hidden = true
                cancelButton.enabled    = false
                cancelButton.hidden     = true
                sendButton.enabled      = false
                sendButton.hidden       = true
                dismissBtn.hidden       = false
                break
            case .PhotoTaken:
                resetProgress()
                imageCaptureView.hidden = false
                videoLayer.hidden       = true
                cancelButton.enabled    = true
                cancelButton.hidden     = false
                sendButton.enabled      = true
                sendButton.hidden       = false
                recordBtn.hidden        = true
                dismissBtn.hidden       = true
                uploadCoordinate        = GPSService.sharedInstance.lastLocation
                break
            case .VideoTaken:
                resetProgress()
                videoLayer.hidden       = false
                cancelButton.enabled    = true
                cancelButton.hidden     = false
                sendButton.enabled      = true
                sendButton.hidden       = false
                recordBtn.hidden        = true
                dismissBtn.hidden       = true
                uploadCoordinate        = GPSService.sharedInstance.lastLocation
                break
            case .Recording:
                dismissBtn.hidden       = true
                break
            case .Sending:
                sendButton.hidden       = true
                sendButton.enabled      = false
                cancelButton.hidden     = true
                cancelButton.enabled    = false

                break
            case .Sent:
                break

            }
        }
    }

    
    var uploadSelector:UploadSelectorView?
    var config: SwiftMessages.Config?
    
    func send(upload:Upload) {
        if cameraState == .PhotoTaken {
            if let image = imageCaptureView.image{
                upload.image = image
                if let uploadTask = FirebaseService.sendImage(upload)
                {
                    self.sent(uploadTask)
                }
            }
        } else if cameraState == .VideoTaken {
            if let url = videoUrl {
                
                playerLayer?.player?.seekToTime(CMTimeMake(0, 1))
                playerLayer?.player?.pause()
                playerLayer?.removeFromSuperlayer()
                videoLayer.hidden = true
           
                print("Send tapped video taken")
                
                let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                let outputUrl = documentsURL.URLByAppendingPathComponent("output.mp4")
                
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(outputUrl)
                }
                catch let error as NSError {
                    if error.code != 4 && error.code != 2 {
                        return print("Error \(error)")
                    }
                }
                upload.videoURL = outputUrl
                FirebaseService.compressVideo(url, outputURL: outputUrl, handler: { session in
                    print("here: \(session.status)")
                    /*
                    T0D0 - HANDLE COMPRESSION ERRORS
                    */
                    dispatch_async(dispatch_get_main_queue(), {
                        FirebaseService.uploadVideo(upload, completionHander: { success, task in
                            if task != nil {
                                self.sent(task!)
                            }
                        })

                    })
                })
            }
        }
    }
    
    func sent(uploadTask:FIRStorageUploadTask) {
        self.tabBarDelegate?.upload(uploadTask)
        self.uploadWrapper.hide()
        
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 1 * Int64(NSEC_PER_SEC))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.cameraState = .Sent
            // Put your code which should be executed with a delay here
            self.dismissViewControllerAnimated(true, completion: nil)
            
        }
    }
    
    @IBAction func sendButtonTapped(sender: UIButton) {
        
        guard let coordinate = uploadCoordinate else { return }
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: [.CurveEaseInOut], animations: {

            self.sendButton.transform = CGAffineTransformMakeScale(0.8, 0.8)
            }, completion: { result in
                self.sendButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
        })
        
        uploadSelector = try! SwiftMessages.viewFromNib() as? UploadSelectorView
        uploadSelector!.configureDropShadow()
        uploadSelector!.delegate = self
        uploadSelector?.setCoordinate(coordinate)
        
        config = SwiftMessages.Config()
        config!.presentationContext = .Window(windowLevel: UIWindowLevelStatusBar)
        config!.duration = .Forever
        config!.presentationStyle = .Bottom
        config!.dimMode = .Gray(interactive: false)
        
        uploadWrapper.show(config: config!, view: uploadSelector!)
    }


    var uploadWrapper = SwiftMessages()
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch))


        view.addGestureRecognizer(pinchGesture)
        
        let definiteBounds = UIScreen.mainScreen().bounds
        recordBtn = CameraButton(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        var cameraBtnFrame = recordBtn.frame
        cameraBtnFrame.origin.y = definiteBounds.height - 152
        cameraBtnFrame.origin.x = self.view.bounds.width/2 - cameraBtnFrame.size.width/2
        recordBtn.frame = cameraBtnFrame
        
        self.view.addSubview(recordBtn)
        recordBtn.hidden = true
        recordBtn.tappedHandler = didPressTakePhoto
        recordBtn.pressedHandler = pressed
        
        
        sendButton.backgroundColor = accentColor
        sendButton.layer.cornerRadius = sendButton.frame.width/2
        sendButton.clipsToBounds = true
        
        sendButton.applyShadow(6, opacity: 0.5, height: 2, shouldRasterize: false)
        
        cameraView.frame = self.view.frame
        
        reloadCamera()
        
        dismissBtn.applyShadow(1, opacity: 0.25, height: 1, shouldRasterize: false)
        cancelButton.applyShadow(1, opacity: 0.25, height: 1, shouldRasterize: false)

    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animateWithDuration(0.6, animations: {
            self.dismissBtn.alpha = 0.5
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarDelegate?.returnToPreviousSelection()
        UIView.animateWithDuration(0.3, animations: {
            self.dismissBtn.alpha = 0.0
        })
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
        
        let captureTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AutoFocusGesture))
        captureTapGesture.numberOfTapsRequired = 1
        captureTapGesture.numberOfTouchesRequired = 1
        view.addGestureRecognizer(captureTapGesture)
        
        do {
            
            let input = try AVCaptureDeviceInput(device: cameraDevice)
            
            videoFileOutput = AVCaptureMovieFileOutput()
            self.captureSession!.addOutput(videoFileOutput)
            let audioDevice: AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
            do {
                let audioInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
                self.captureSession!.addInput(audioInput)

            } catch {
                print("Unable to add audio device to the recording.")
            }
            
            if captureSession?.canAddInput(input) != nil {
                captureSession?.addInput(input)
                stillImageOutput = AVCaptureStillImageOutput()
                stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                
                if (captureSession?.canAddOutput(stillImageOutput) != nil) {
                    captureSession?.addOutput(stillImageOutput)
                    
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    previewLayer?.session.usesApplicationAudioSession = false

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
    
    
    func pinch(pinch: UIPinchGestureRecognizer) {
        
        var vZoomFactor = pinch.scale
        
        if vZoomFactor >= 1 {
            var error:NSError!
            do{
                try cameraDevice!.lockForConfiguration()
                defer {cameraDevice!.unlockForConfiguration()}
                if (vZoomFactor <= cameraDevice!.activeFormat.videoMaxZoomFactor){
                    cameraDevice!.videoZoomFactor = vZoomFactor
                }else{
                    NSLog("Unable to set videoZoom: (max %f, asked %f)", cameraDevice!.activeFormat.videoMaxZoomFactor, vZoomFactor);
                }
            }catch error as NSError{
                NSLog("Unable to set videoZoom: %@", error.localizedDescription);
            }catch _{
                
            }
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
                }
                switch flashMode {
                case .On:
                    
                    avDevice.flashMode = .Auto
                    flashMode = .Auto
                    break
                case .Auto:
                    avDevice.flashMode = .Off
                    flashMode = .Off
                    break
                case .Off:
                    avDevice.flashMode = .On
                    flashMode = .On
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
        recordBtn.updateProgress(progress)
        
        if progress >= 1 {
            progressTimer.invalidate()
        }
        
    }
    
    func resetProgress() {
        progress = 0
        recordBtn.resetProgress()
    }
    
    
    func pressed(state: UIGestureRecognizerState)
    {
        switch state {
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
        flashView.alpha = 0.0
        UIView.animateWithDuration(0.025, animations: {
            self.flashView.alpha = 0.75
            }, completion: { result in
                UIView.animateWithDuration(0.25, animations: {
                    self.flashView.alpha = 0.0
                    }, completion: { result in })
        })

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
                    self.imageCaptureView.image = image
                    self.cameraState = .PhotoTaken
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
        progressTimer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
        
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
    
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}