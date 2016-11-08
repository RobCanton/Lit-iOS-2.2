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
}

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, AVCaptureFileOutputRecordingDelegate, UploadSelectorDelegate, UITextViewDelegate, UIGestureRecognizerDelegate {
    
    var interactor:Interactor? = nil
    
    func handlePanGesture(sender: UIPanGestureRecognizer) {
        let percentThreshold:CGFloat = 0.1
        
        // convert y-position to downward pull progress (percentage)
        let translation = sender.translationInView(view)
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)

        guard let interactor = interactor else { return }

        switch sender.state {
        case .Began:
            interactor.hasStarted = true
            dismissViewControllerAnimated(true, completion: nil)
        case .Changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.updateInteractiveTransition(progress)
        case .Cancelled:
            interactor.hasStarted = false
            interactor.cancelInteractiveTransition()
        case .Ended:
            interactor.hasStarted = false
            interactor.shouldFinish
                ? interactor.finishInteractiveTransition()
                : interactor.cancelInteractiveTransition()
        default:
            break
        }
    }
    
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

    /* 
     GESTURES 
     */
    var panGesture:UIPanGestureRecognizer!
    var pinchGesture:UIPinchGestureRecognizer!
    var textTapGesture:UITapGestureRecognizer!
    var labelDragGesture:UIPanGestureRecognizer!
    var labelPinchGesture:UIPinchGestureRecognizer!
    var labelRotateGesture:UIRotationGestureRecognizer!
    
    var cameraState:CameraState = .Initiating
        {
        didSet {
            switch cameraState {
            case .Initiating:
                cancelButton.enabled = false
                cancelButton.hidden = true
                sendButton.enabled = false
                sendButton.hidden = true
                textView.hidden = true
                break
            case .Running:
                imageCaptureView.image = nil
                imageCaptureView.hidden = true
                recordButton.buttonState = .Idle
                cancelButton.enabled = false
                cancelButton.hidden = true
                sendButton.enabled = false
                sendButton.hidden = true
                flashButton.enabled = true
                flashButton.hidden = false
                flipButton.enabled = true
                flipButton.hidden = false
                textView.hidden = true
                textView.text = ""
                textLabel.hidden = true
                textLabel.text = ""
                view.removeGestureRecognizer(textTapGesture)
                view.addGestureRecognizer(panGesture)
                break
            case .PhotoTaken:
                resetProgress()

                imageCaptureView.hidden = false
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
                view.removeGestureRecognizer(panGesture)
                view.addGestureRecognizer(textTapGesture)
                break
            case .VideoTaken:
                resetProgress()
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
                view.removeGestureRecognizer(panGesture)
                view.addGestureRecognizer(textTapGesture)
                break
            case .Recording:
                flashButton.enabled = false
                flashButton.hidden = true
                flipButton.enabled = false
                flipButton.hidden = true
                break
            case .Sending:
                sendButton.hidden = true
                sendButton.enabled = false
                cancelButton.hidden = true
                cancelButton.enabled = false
                view.userInteractionEnabled = false
                break
            case .Sent:
                self.dismissViewControllerAnimated(true, completion: {})
                break

            }
        }
    }
    
    @IBOutlet weak var videoLayer: UIView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var snapButton: UIButton!
    
    
    @IBOutlet weak var textView: UITextView!
    var textLabel = UITextView()

    @IBOutlet weak var cancelButton: UIButton!
    @IBAction func cancelButtonTapped(sender: UIButton) {
        
        playerLayer?.player?.seekToTime(CMTimeMake(0, 1))
        playerLayer?.player?.pause()
        
        playerLayer?.removeFromSuperlayer()
        videoUrl = nil
        
        cameraState = .Running
    }
    @IBOutlet weak var sendButton: UIButton!
    
    var uploadSelector:UploadSelectorView?
    var config: SwiftMessages.Config?
    
    func send(upload:Upload) {
        if cameraState == .PhotoTaken {
            
            if let image = imageCaptureView.image {
                
                upload.image = printTextOnImage()
                if let uploadTask = FirebaseService.sendImage(upload)
                {
                    SwiftMessages.hide()
                    cameraState = .Sent
                }
            }
        }
    }
    
    @IBAction func sendButtonTapped(sender: UIButton) {
        print("fam")
        SwiftMessages.show(config: config!, view: uploadSelector!)
        
//        if cameraState == .PhotoTaken {
//            if let image = imageView.image {
        
//                self.imageView.hidden = true
//                print("Sending dat image")
//                if let uploadTask = FirebaseService.sendImage(image)
//                {
//                    self.delegate?.close(uploadTask, outputUrl: nil)
//                }
//            }
//        }
//        else if cameraState == .VideoTaken {
//            playerLayer?.player?.seekToTime(CMTimeMake(0, 1))
//            playerLayer?.player?.pause()
//            
//            playerLayer?.removeFromSuperlayer()
//            videoLayer.hidden = true
//            
//            print("Send tapped video taken")
//            
//            if let url = videoUrl {
//                
//                let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
//                let outputUrl = documentsURL.URLByAppendingPathComponent("output.mp4")
//                
//                FirebaseService.compressVideo(url, outputURL: outputUrl, handler: { session in
//                    print("here: \(session.status)")
//                    /*
//                    T0D0 - HANDLE COMPRESSION ERRORS
//                    */
//                    dispatch_async(dispatch_get_main_queue(), {
//                        if let uploadTask = FirebaseService.uploadVideo(outputUrl) {
//                            self.videoUrl = nil
//                            self.delegate?.close(uploadTask, outputUrl: outputUrl)
//                        }
//                    })
//                })
//            }
//        }
        
        //cameraState = .Running
    }

    var recordButton: RecordButton!
    var flashButton: UIButton!
    var flipButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        textTapGesture = UITapGestureRecognizer(target: self, action: #selector(enableTextField))
        labelDragGesture = UIPanGestureRecognizer(target: self, action: #selector(labelDragged))
        labelPinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(labelPinched))
        labelRotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(labelRotated))
        labelDragGesture.delegate = self
        labelPinchGesture.delegate = self
        labelRotateGesture.delegate = self
        
        view.addGestureRecognizer(panGesture)
        view.addGestureRecognizer(pinchGesture)
        
        sendButton.backgroundColor = accentColor
        sendButton.layer.cornerRadius = sendButton.frame.width/2
        sendButton.clipsToBounds = true
        sendButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        
        sendButton.applyShadow(4, opacity: 0.7, height: 3, shouldRasterize: false)
        
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
        
        uploadSelector = try! SwiftMessages.viewFromNib() as? UploadSelectorView
        uploadSelector!.configureDropShadow()
        uploadSelector!.delegate = self
        config = SwiftMessages.Config()
        config!.presentationContext = .Window(windowLevel: UIWindowLevelStatusBar)
        config!.duration = .Forever
        config!.presentationStyle = .Bottom
        config!.dimMode = .Gray(interactive: true)
        
        textView.backgroundColor = UIColor.clearColor()
        textView.textColor = UIColor.whiteColor()
        textView.font = UIFont(name: "Avenir-BlackOblique", size: 40.0)
        textView.textAlignment = .Center
        textView.scrollEnabled = false
        
        textView.keyboardAppearance = .Dark
        textView.delegate = self
        textView.editable = false
        textView.applyShadow(1, opacity: 0.5, height: 1, shouldRasterize: false)

        textLabel.backgroundColor = UIColor.clearColor()
        textLabel.textColor = UIColor.whiteColor()
        textLabel.font = UIFont(name: "Avenir-BlackOblique", size: 40.0)
        textLabel.textAlignment = .Center
        textLabel.editable = false
        textLabel.scrollEnabled = false
        textLabel.selectable = false
        textLabel.applyShadow(1, opacity: 0.5, height: 1, shouldRasterize: false)
        textLabel.addGestureRecognizer(labelDragGesture)
        textLabel.addGestureRecognizer(labelPinchGesture)
        textLabel.addGestureRecognizer(labelRotateGesture)
        textLabel.center = textView.center
        textLabel.frame = textLabel.frame

        editingLayer.addSubview(textLabel)
        editingLayer.userInteractionEnabled = true
    
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        textView.hidden = false
        textLabel.hidden = true
        textLabel.userInteractionEnabled = false
        
        UIView.animateWithDuration(0.2, animations: {
            self.editingFadeLayer.alpha = 0.24
        })
    }
    
    @IBOutlet weak var editingFadeLayer: UIView!
    func textViewDidEndEditing(textView: UITextView) {
        textView.hidden = true
        textView.editable = false
        adjustFrames()
        //textView.sizeToFit()
        //textView.center = CGPoint(x: view.frame.width/2, y: view.frame.height/2)
        textLabel.transform = CGAffineTransformIdentity
        textLabel.frame = textView.frame
        textLabel.text = textView.text
        
//        if let center = labelCenter {
//            textLabel.center = center
//        }
//        if let transform = transform {
//            //print("scale \(scale)")
//            textLabel.transform = transform
//        }

        textLabel.hidden = false
        textLabel.userInteractionEnabled = true
        UIView.animateWithDuration(0.2, animations: {
            self.editingFadeLayer.alpha = 0.0
        })
    }
    
    
    
    @IBOutlet weak var editingLayer: UIView!
    func printTextOnImage() -> UIImage{
        UIGraphicsBeginImageContextWithOptions(UIScreen.mainScreen().bounds.size, false, 0);
        self.editingLayer.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
        let image:UIImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return image;
    }
    
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        let newText = (textView.text as NSString).stringByReplacingCharactersInRange(range, withString: text)
        let numberOfChars = newText.characters.count // for Swift use count(newText)
        return numberOfChars < 80;
    }
    
    func enableTextField(gesture:UITapGestureRecognizer) {
        if !textView.isFirstResponder() {
            textView.editable = true
            textView.becomeFirstResponder()
        } else {
            textView.resignFirstResponder()
        }
    }
    

    
    func adjustFrames() {
        let fixedWidth = textView.frame.size.width
        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        var newFrame = textView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        textView.frame = newFrame;
        textView.center = view.center
    }
    
    var labelCenter:CGPoint?
    var labelFrame:CGRect?
    func labelDragged(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translationInView(self.view) // get the translation
        let label = gesture.view! // the view inside the gesture

        // move the label with the translation
        label.center = CGPoint(x: label.center.x + translation.x, y: label.center.y + translation.y)
        
        // reset the translation that now, is already applied to the label
        gesture.setTranslation(CGPointZero, inView: self.view)
        
        if gesture.state == UIGestureRecognizerState.Ended {
            labelCenter = label.center
        }
    }
    
    var _scale:CGFloat?
    {
        didSet{
            print(_scale!)
        }
    }
    var transform:CGAffineTransform?
    func labelPinched(gesture: UIPinchGestureRecognizer) {
        _scale = gesture.scale
        transform = CGAffineTransformScale(gesture.view!.transform, _scale!, _scale!)
        gesture.view!.transform = transform!
        gesture.scale = 1.0
    }
    
    func labelRotated(sender:UIRotationGestureRecognizer){
        textLabel.transform = CGAffineTransformRotate(textLabel.transform, sender.rotation)
        // Reset recognizer rotation
        sender.rotation = 0
    }
    
    @IBOutlet weak var imageCaptureView: UIImageView!
    
    
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
        view.addGestureRecognizer(captureTapGesture)
        
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
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}