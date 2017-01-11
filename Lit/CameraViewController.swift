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
    func upload(uploadTask:FIRStorageUploadTask)
    func returnToPreviousSelection()
}

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, AVCaptureFileOutputRecordingDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var imageCaptureView: UIImageView!
    @IBOutlet weak var videoLayer: UIView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var dismissBtn: UIButton!
    


    
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
    
    var flashButton:UIButton!
    var switchButton:UIButton!
    
    var flashView:UIView!
    
    lazy var cancelButton: UIButton = {
        let definiteBounds = UIScreen.mainScreen().bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        button.setImage(UIImage(named: "delete_filled"), forState: .Normal)
        button.center = CGPoint(x: button.frame.width * 0.75, y: definiteBounds.height - button.frame.height * 0.75)
        button.tintColor = UIColor.whiteColor()
        return button
    }()
    
    lazy var sendButton: UIButton = {
        let definiteBounds = UIScreen.mainScreen().bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
        button.setImage(UIImage(named: "right_arrow"), forState: .Normal)
        button.center = CGPoint(x: definiteBounds.width - button.frame.width * 0.75, y: definiteBounds.height - button.frame.height * 0.75)
        button.tintColor = UIColor.whiteColor()
        button.backgroundColor = accentColor
        button.layer.cornerRadius = button.frame.width / 2
        button.clipsToBounds = true
        button.applyShadow(2.0, opacity: 0.5, height: 1.0, shouldRasterize: false)
        return button
    }()
    

    
    var cameraState:CameraState = .Initiating
        {
        didSet {
            switch cameraState {
            case .Initiating:
                
                break
            case .Running:
                imageCaptureView.image  = nil
                imageCaptureView.hidden = true
                
                playerLayer?.player?.pause()
                playerLayer?.removeFromSuperlayer()
                playerLayer?.player = nil
                playerLayer = nil
                
                showCameraOptions()
                hideEditOptions()
                break
            case .PhotoTaken:
                resetProgress()
                imageCaptureView.hidden = false
                videoLayer.hidden       = true
                recordBtn.hidden        = true
                hideCameraOptions()
                showEditOptions()
                uploadCoordinate        = GPSService.sharedInstance.lastLocation
                break
            case .Recording:
                hideCameraOptions()
                break
            case .VideoTaken:
                resetProgress()
                videoLayer.hidden       = false
                recordBtn.hidden        = true
                
                hideCameraOptions()
                showEditOptions()
                uploadCoordinate        = GPSService.sharedInstance.lastLocation
                break
            }
        }
    }
    
    func showCameraOptions() {
        dismissBtn.hidden       = false
        flashButton.enabled     = true
        flashButton.hidden      = false
        switchButton.enabled    = true
        switchButton.hidden     = false
    }
    
    func hideCameraOptions() {
        dismissBtn.hidden       = true
        flashButton.enabled     = false
        flashButton.hidden      = true
        switchButton.enabled    = false
        switchButton.hidden     = true
    }
    
    func showEditOptions() {
        self.view.addSubview(cancelButton)
        self.view.addSubview(sendButton)
        
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), forControlEvents: .TouchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), forControlEvents: .TouchUpInside)
    }
    
    func hideEditOptions() {
        cancelButton.removeFromSuperview()
        sendButton.removeFromSuperview()
        
        cancelButton.removeTarget(self, action: #selector(cancelButtonTapped), forControlEvents: .TouchUpInside)
        sendButton.removeTarget(self, action: #selector(sendButtonTapped), forControlEvents: .TouchUpInside)
    }

    
    func sendButtonTapped(sender: UIButton) {
        
        let upload = Upload()
        if cameraState == .PhotoTaken {
            upload.image = imageCaptureView.image!
        } else if cameraState == .VideoTaken {
            upload.videoURL = videoUrl
        }
        
        upload.coordinates = uploadCoordinate
        
        let nav = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewControllerWithIdentifier("SendOffNavigationController") as! UINavigationController
        let controller = nav.viewControllers[0] as! SendViewController
        controller.upload = upload
        
        self.presentViewController(nav, animated: false, completion: nil)
    }
    
    func cancelButtonTapped(sender: UIButton) {
        
        playerLayer?.player?.seekToTime(CMTimeMake(0, 1))
        playerLayer?.player?.pause()
        
        playerLayer?.removeFromSuperlayer()
        videoUrl = nil
        
        recordBtn.hidden = false
        cameraState = .Running
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let definiteBounds = UIScreen.mainScreen().bounds
       
        flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.whiteColor()
        flashView.alpha = 0.0
        
        recordBtn = CameraButton(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        var cameraBtnFrame = recordBtn.frame
        cameraBtnFrame.origin.y = definiteBounds.height - 140
        cameraBtnFrame.origin.x = self.view.bounds.width/2 - cameraBtnFrame.size.width/2
        recordBtn.frame = cameraBtnFrame
        
        recordBtn.hidden = true
        recordBtn.tappedHandler = didPressTakePhoto
        recordBtn.pressedHandler = pressed
        
        cameraView.frame = self.view.frame
        
        flashButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        flashButton.setImage(UIImage(named: "flashoff"), forState: .Normal)
        flashButton.center = CGPoint(x: cameraBtnFrame.origin.x / 2, y: cameraBtnFrame.origin.y + cameraBtnFrame.height / 2)
        flashButton.alpha = 0.6
        
        switchButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        switchButton.setImage(UIImage(named: "switchcamera"), forState: .Normal)
        switchButton.center = CGPoint(x: view.frame.width - cameraBtnFrame.origin.x / 2, y: cameraBtnFrame.origin.y + cameraBtnFrame.height / 2)
        switchButton.alpha = 0.6
        
        self.view.insertSubview(flashView, aboveSubview: imageCaptureView)
        self.view.addSubview(recordBtn)
        self.view.addSubview(flashButton)
        self.view.addSubview(switchButton)
        
        flashButton.addTarget(self, action: #selector(switchFlashMode), forControlEvents: .TouchUpInside)
        switchButton.addTarget(self, action: #selector(switchCamera), forControlEvents: .TouchUpInside)
        
        reloadCamera()

        dismissBtn.applyShadow(1, opacity: 0.25, height: 1, shouldRasterize: false)

    
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        view.addGestureRecognizer(pinchGesture)
        
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animateWithDuration(0.6, animations: {
            self.dismissBtn.alpha = 0.6
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarDelegate?.returnToPreviousSelection()
        UIView.animateWithDuration(0.3, animations: {
            self.dismissBtn.alpha = 0.0
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        playerLayer?.player = nil
        playerLayer = nil
        
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
    
    func endLoopVideo() {
        NSNotificationCenter.defaultCenter().removeObserver(AVPlayerItemDidPlayToEndTimeNotification, name: nil, object: nil)
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