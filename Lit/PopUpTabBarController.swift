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
//        let color:CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
//        color.fromValue = cameraButton.layer.borderColor
//        color.toValue = accentColor.CGColor
//        cameraButton.layer.borderColor = accentColor.CGColor
//        
//        let Width:CABasicAnimation = CABasicAnimation(keyPath: "borderWidth")
//        Width.fromValue = cameraButton.layer.borderWidth
//        Width.toValue = cameraActiveWidth
//
//        cameraButton.layer.borderWidth = cameraActiveWidth
//        
//        let both:CAAnimationGroup = CAAnimationGroup()
//        both.duration = 1.0
//        both.animations = [color,Width]
//        both.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
//        
//        cameraButton.layer.addAnimation(both, forKey: "color and Width")

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
    let cameraDefaultWidth:CGFloat = 2.2
    let cameraActiveWidth:CGFloat = 4
    var cameraActivity:NVActivityIndicatorView!
    func setupMiddleButton() {
        if cameraButton == nil {
            cameraButton = UIButton(frame: CGRect(x: 0, y: 0, width: 56, height: 56))
            var menuButtonFrame = cameraButton.frame
            menuButtonFrame.origin.y = self.tabBar.bounds.height - menuButtonFrame.height - 8
            menuButtonFrame.origin.x = self.tabBar.bounds.width/2 - menuButtonFrame.size.width/2
            cameraButton.frame = menuButtonFrame
            
            cameraButton.backgroundColor = UIColor.blackColor()
            cameraButton.layer.cornerRadius = menuButtonFrame.height/2
            cameraButton.layer.borderColor = UIColor.whiteColor().CGColor
            cameraButton.layer.borderWidth = cameraActiveWidth
            //menuButton.setImage(UIImage(named: "camera"), forState: UIControlState.Normal)
            cameraButton.tintColor = UIColor.whiteColor()
            cameraButton.addTarget(self, action: #selector(presentCamera), forControlEvents: .TouchUpInside)
            
            self.tabBar.addSubview(cameraButton)
            
            cameraActivity = NVActivityIndicatorView(frame: cameraButton.bounds, type: .BallScale, color: UIColor.whiteColor(), padding: 1.0)
            self.cameraButton.addSubview(cameraActivity)
            cameraActivity.userInteractionEnabled = false
            
            
//            let purple = UIColor(red: 189/255, green: 106/255, blue: 252/255, alpha: 1.0)
//            let angleGradientBorderView1Colors: [AnyObject] = [
//                accentColor.CGColor,
//                UIColor.purpleColor().CGColor,
//                accentColor.CGColor
//                ]
//            
////            let circle = AngleGradientBorderView(frame: menuButtonFrame)
////            circle.setupGradientLayer(borderColors: angleGradientBorderView1Colors, borderWidth: cameraActiveWidth)
////            circle.clipsToBounds = true
////            circle.layer.cornerRadius = circle.frame.width/2
////            circle.backgroundColor = UIColor.clearColor()
////
////            self.tabBar.addSubview(circle)
            
            
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

    
    @IBAction func unwindFromViewController(sender: UIStoryboardSegue) {
    }
    
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        let segue = CameraUnwindTransition(identifier: identifier, source: fromViewController, destination: toViewController)

        return segue
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

        dispatch_async(dispatch_get_main_queue(), {
            if self.visible {

    
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                self.tabBar.alpha = 1.0

                
                }, completion: { result in })
        } else {
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                self.tabBar.alpha = 0.0

                }, completion: { result in

            })
        }
        })
        
    }
    
}