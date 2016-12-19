//
//  PopUpTabBarController.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-17.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import ReSwift
import Firebase
import CoreLocation
import SwiftMessages

class PopUpTabBarController: UITabBarController, StoreSubscriber, UITabBarControllerDelegate, GPSServiceDelegate, PopUpProtocolDelegate {
    
    var activeLocation:Location?
    
    var visible = true
    
    let tabBarHeight:CGFloat = 54
    var selectedItem = 0
    
    let locationManager = CLLocationManager()
    
    func tracingLocation(currentLocation: CLLocation){
        print("New Location:\n\(currentLocation)")
        
        let lat = currentLocation.coordinate.latitude
        let lon = currentLocation.coordinate.longitude
        LocationService.requestNearbyLocations(lat, longitude: lon)
    }
    
    func tracingLocationDidFailWithError(error: NSError) {
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self) 
    }
    
    func newState(state: AppState) {
        if !state.userState.isAuth {
           self.performSegueWithIdentifier("logout", sender: self)
        }
        
        messageNotifications()
        socialNotifications()
        
        let currentKey = state.userState.activeLocationKey

        if let _ = activeLocation {
            if currentKey == activeLocation?.getKey() { return }
        }
        var loc:Location?
        for location in state.locations {
            if location.getKey() == currentKey {
                loc = location
            }
        }
        
        if loc == nil {
            deactivateLocation()
        } else {
            activateLocation(loc!)
        }
    }
    
    var messageView:ActiveLocationView?
    var bannerWrapper = SwiftMessages()
    
    
    func activateLocation(location:Location) {
        activeLocation = location
        //cameraButton.layer.borderColor = accentColor.CGColor
        //array[2].alpha = 1.0
//        print("ACTIVE LOCATION: \(activeLocation!.getKey())")
//        
//        messageView = try! SwiftMessages.viewFromNib() as? ActiveLocationView
//        messageView!.configureDropShadow()
//        
//        
//        var config = SwiftMessages.Config()
//        config.presentationContext = .Window(windowLevel: UIWindowLevelAlert)
//        config.duration = .Forever
//        config.presentationStyle = .Top
//        config.dimMode = .None
        //SwiftMessages.show(config: config, view: messageView!)
        
    }
    
    func deactivateLocation() {
        activeLocation = nil
        cameraButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        SwiftMessages.hide()
    }
    
    
    func messageNotifications() {
        var count = 0
        for conversation in mainStore.state.conversations {
            if !conversation.seen {
                count += 1
            }
        }
        if count > 0 {
            tabBar.items?[3].badgeValue = "\(count)"
        } else {
            tabBar.items?[3].badgeValue = nil
        }
    }
    
    func socialNotifications() {
        var count = 0
        for (_, seen) in mainStore.state.friendRequestsIn {
            if !seen {
                count += 1
            }
        }
        
        if count > 0 {
            tabBar.items?[4].badgeValue = "\(count)"
        } else {
            tabBar.items?[4].badgeValue = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        tabBarController?.delegate = self
//        tabBar.backgroundImage = UIImage()
//        tabBar.backgroundColor = UIColor.clearColor()
//        tabBar.shadowImage = UIImage()
        tabBar.translucent = false
        tabBar.backgroundColor = UIColor.blackColor()
        
        
        self.tabBar.setValue(true, forKey: "_hidesShadow")
        
        GPSService.sharedInstance.delegate = self
        GPSService.sharedInstance.startUpdatingLocation()
        
        self.setupMiddleButton()
    }
    
    var cameraButton:UIButton!
    
    func setupMiddleButton() {
        if cameraButton == nil {
            cameraButton = UIButton(frame: CGRect(x: 0, y: 0, width: 56, height: 56))
            var menuButtonFrame = cameraButton.frame
            menuButtonFrame.origin.y = self.view.bounds.height - menuButtonFrame.height - 8
            menuButtonFrame.origin.x = self.view.bounds.width/2 - menuButtonFrame.size.width/2
            cameraButton.frame = menuButtonFrame
            
            cameraButton.backgroundColor = UIColor.blackColor()
            cameraButton.layer.cornerRadius = menuButtonFrame.height/2
            cameraButton.layer.borderColor = UIColor.whiteColor().CGColor
            cameraButton.layer.borderWidth = 3
            //menuButton.setImage(UIImage(named: "camera"), forState: UIControlState.Normal)
            cameraButton.tintColor = UIColor.whiteColor()
            cameraButton.addTarget(self, action: #selector(presentCamera), forControlEvents: .TouchUpInside)
            
            self.view.addSubview(cameraButton)
            
            self.view.layoutIfNeeded()
        }
    }
    
    func presentCamera() {
        self.performSegueWithIdentifier("toCamera", sender: self)
    }
    
    override func viewWillLayoutSubviews() {
    }
    
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {

    }
    
    var prevSelection = 0
    internal func highlightItem(itemTag:Int)
    {
        selectedItem = itemTag

        UIView.animateWithDuration(0.15, animations: {

            }, completion:  { complete in
                if itemTag == 2 {
                } else {
                    self.prevSelection = itemTag
                }
        })
    }
    
    func close(uploadTask: FIRStorageUploadTask, outputUrl: NSURL?) {
    }
   
    func addProgressView() {
        var status = try! SwiftMessages.viewFromNib() as? ActiveLocationView
        status!.configureDropShadow()

        var config = SwiftMessages.Config()
        config.presentationContext = .Window(windowLevel: UIWindowLevelAlert)
        config.duration = .Forever
        config.presentationStyle = .Top
        config.dimMode = .None
        
        let wrapper = SwiftMessages()
        wrapper.show(config: config, view: status!)
    }
    
    func upload(uploadTask: FIRStorageUploadTask) {
        addProgressView()
        uploadTask.observeStatus(.Progress, handler: { snapshot in
            print("PROGRESS: \(snapshot.progress)")
        })
    }
    
    func returnToPreviousSelection() {
        self.selectedIndex = prevSelection
        highlightItem(prevSelection)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destinationViewController = segue.destinationViewController as? CameraViewController {
            destinationViewController.transitioningDelegate = self
            destinationViewController.interactor = interactor
            destinationViewController.tabBarDelegate = self
        }
    }
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if viewController.isKindOfClass(DummyViewController) {
            return false
        }
        return true
    }
    
    
    func setTabBarVisible(_visible:Bool, animated:Bool) {
        
        if visible == _visible {
            return
        }
        visible = _visible

        // get a frame calculation ready
        let frame = self.tabBar.frame
        
        let height = frame.size.height
        let cameraFrame = self.cameraButton.frame
        if visible {
            let offsetY =  -height

            
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                self.tabBar.alpha = 1.0
                self.cameraButton.alpha = 1.0

                
                }, completion: { result in })
        } else {
            let offsetY = height
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                self.tabBar.alpha = 0.0
                self.cameraButton.alpha = 0.0

                }, completion: { result in

            })
        }
        
        
    }
    
    
    let interactor = Interactor()
    
    
    
    
}

extension PopUpTabBarController: UIViewControllerTransitioningDelegate {
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}