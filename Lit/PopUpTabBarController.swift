//
//  PopUpTabBarController.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-17.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import LNPopupController
import ReSwift
import Firebase

class PopUpTabBarController: UITabBarController, StoreSubscriber, PopUpProtocolDelegate {
    
    var popupVC:PopupViewController!
    
    var activeLocation:Location?
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self, selector: { state in
            state.userState
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self) 
    }
    
    func newState(state: UserState) {
        
        let key = state.activeLocationKey
        if key != activeLocation?.getKey() {
            for location in mainStore.state.locations {
                if key == location.getKey() {
                    print("PopUpTabBarController: New Active Location \(location.getKey())")
                    activeLocation = location
                    presentPopupBar()
                }
            }
        }
        
        var unseenActivity = 0
        for (_, seen) in mainStore.state.friendRequestsIn {
            if !seen {
                unseenActivity += 1
            }
        }
        if unseenActivity > 0 {
            tabBar.items?[2].badgeValue = "\(unseenActivity)"
        } else {
            tabBar.items?[2].badgeValue = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popupVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PopupViewController") as! PopupViewController
        popupVC.view.backgroundColor = UIColor.clearColor()
        popupVC.popupBar?.tintColor = UIColor.whiteColor()
        popupVC.cameraViewController.delegate = self
        
        
        
        
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let change = change else {
            return
        }
        
        if let key = keyPath {
            if key == "center" {
                if let newCenter = change["new"]?.CGPointValue() {
                    barTitleView.alpha = max(0, -0.7 + (max(0,newCenter.y) / self.view.frame.height) * 1.3)
                    popupVC.scrollView.alpha =  1 - max(0, -0.2 + (max(0,newCenter.y) / self.view.frame.height) * 1.8)
                }
            } else if key == "frame" {
                if let newFrame = change["new"]?.CGRectValue() {
                    if (newFrame.origin.y > 0) {
                        barTitleView.alpha = 1
                        popupVC.scrollView.alpha = 0
                    } else {
                        barTitleView.alpha = 0
                        popupVC.scrollView.alpha = 1
                        
                    }
                }
            }
        }
        
        
        

    }
    
    let barTitleView = UIView()
    let barTitle = UILabel()
    let progressView = UIProgressView()
    func presentPopupBar() {
        
        //"You are near \(activeLocation!.getName())"popupVC.popupItem.title = "You are near \(activeLocation!.getName())"

        self.presentPopupBarWithContentViewController(popupVC, animated: true, completion: nil)
        self.openPopupAnimated(true, completion: {})
//        popupBar!.titleTextAttributes = [
//                NSFontAttributeName : UIFont(name: "Avenir", size: 20.0)!,
//        ]
        popupBar?.barTintColor = UIColor.clearColor()
        popupBar?.backgroundImage = UIImage()
        popupBar?.tintColor = accentColor
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        let bounds = popupBar!.bounds
        blurView.frame = CGRect(x: 0, y: -bounds.height / 2, width: bounds.width, height: bounds.height * 1.5)
        

        popupBar?.addSubview(blurView)
        popupBar?.layer.borderColor = UIColor.clearColor().CGColor
        popupBar?.layer.borderWidth = 0.0
        
        barTitle.frame = blurView.frame
        barTitle.textAlignment = .Center
        barTitle.numberOfLines = 2
        
        
        progressView.frame = CGRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 0.5)
        progressView.progress = 0.0
        progressView.trackTintColor = UIColor.clearColor()
        barTitleView.addSubview(progressView)
        
        barTitle.styleLocationTitleWithPreText("You are at\n\(activeLocation!.getName().uppercaseString)", size1: 24.0, size2: 11.0)

        barTitleView.addSubview(barTitle)
        popupBar?.addSubview(barTitleView)
        popupBar!.addObserver(self, forKeyPath: "center", options: .New, context: nil)
        popupBar!.addObserver(self, forKeyPath: "frame", options: .New, context: nil)

    
    }
    
    
    
    
    func presentCamera() {
        popupVC.movetoCamera()
        self.openPopupAnimated(true, completion: {})
    }
    
    func presentVisitors() {
        popupVC.movetoVisitors()
        self.openPopupAnimated(true, completion: {})
    }
    
    
    func close(uploadTask:FIRStorageUploadTask, outputUrl: NSURL?) {
        
        self.closePopupAnimated(true, completion: nil)
        
        uploadTask.observeStatus(.Progress) { snapshot in
            if let progress = snapshot.progress {
                let percentComplete = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
                print("Progress: \(percentComplete)")
                self.progressView.setProgress(percentComplete, animated: true)
                //self.barTitle.text = "Uploading - \(round(min(100, percentComplete * 100)))%"
                self.barTitle.styleLocationTitleWithPreText("Uploading to\n\(self.activeLocation!.getName().uppercaseString)", size1: 24.0, size2: 11.0)
            }
        }
        
        uploadTask.observeStatus(.Success) { snapshot in
            self.popupBar?.popupItem?.progress = 1.0
            NSTimer.scheduledTimerWithTimeInterval(1.25, target: self, selector: #selector(self.resetUploadBar), userInfo: nil, repeats: false)
            if let url = outputUrl {
                let fileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.removeItemAtURL(url)
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
            }
        }
    }
    
    func resetUploadBar() {
        barTitle.styleLocationTitleWithPreText("You are at\n\(activeLocation!.getName().uppercaseString)", size1: 24.0, size2: 11.0)
        self.progressView.progress = 0.0
    }
}