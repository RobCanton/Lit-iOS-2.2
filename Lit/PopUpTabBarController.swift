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
import Whisper


class PopUpTabBarController: UITabBarController, StoreSubscriber, UITabBarControllerDelegate, GPSServiceDelegate, PopUpProtocolDelegate, CLLocationManagerDelegate, NotificationDelegate {
    
    var activeLocation:Location?
    
    var visible = true
    
    let tabBarHeight:CGFloat = 54
    var selectedItem = 0
    
    let locationManager = CLLocationManager()
    
    func tracingLocation(currentLocation: CLLocation){
        
        let lat = currentLocation.coordinate.latitude
        let lon = currentLocation.coordinate.longitude
        LocationService.requestNearbyLocations(lat, longitude: lon)
    }
    
    func tracingLocationDidFailWithError(error: NSError) {
        
    }
    
    func messageRecieved(senderId: String, message: String) {
        
        FirebaseService.getUser(senderId, completionHandler: { user in
            if user != nil {
                loadImageUsingCacheWithURL(user!.getImageUrl() , completion: { _image, fromCache in
                    guard let image = _image else { return }
                    guard let controller = self.selectedViewController as? MasterNavigationController else { return }
                    let announcement = Announcement(title: user!.getDisplayName(), subtitle: message, image: image, duration: 4, action: {
                        print("Tapped announcement")
                    })
                    show(shout: announcement, to: controller, completion: {
                        print("The shout was silent.")
                    })
                })
            }
        })
    }
    
    func newFollower(uid: String) {
        
        let murmur = Murmur(title: uid)
        
        // Show and hide a message after delay
        show(whistle: murmur, action: .Show(3.0))
    }
    
    func changeTab(index:Int) {
        self.selectedIndex = index
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
        
        var activeLocations = [Location]()
        for location in mainStore.state.locations {
            if location.isActive() {
                activeLocations.append(location)
            }
        }
        
        if activeLocations.count > 0 {
            activateLocation()
            var title:String!
            if activeLocations.count == 1 {
                title = "You are near \(activeLocations[0].getName())"
            } else {
                title = "You are near \(activeLocations.count) locations"
            }
            let whisper = Murmur(title: title, backgroundColor: accentColor, titleColor: UIColor.whiteColor(), font: UIFont(name: "AvenirNext-Medium", size: 12.0)!)
            
            //show(whistle: whisper, action: .Present)
            
        } else {
            deactivateLocation()
            hide()
        }
        
    }

    
    var isActive = false
    
    func activateLocation() {
        if isActive { return }
        isActive = true
        
        cameraActivity?.startAnimating()
        
    }
    
    func deactivateLocation() {
        if !isActive { return }
        isActive = false
        cameraButton.layer.borderColor = UIColor.whiteColor().CGColor
        cameraActivity?.stopAnimating()
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
    
    var _center:CGPoint!
    var _hiddenCenter:CGPoint!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _center = tabBar.center
        _hiddenCenter = CGPoint(x: _center.x, y: _center.y * 2)
        

        visibleFrame = tabBar.frame
        hiddenFrame = CGRect(x: visibleFrame.origin.x, y: visibleFrame.origin.y, width: visibleFrame.width, height: 0)
        
        visibleViewFrame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height )
        
        //self.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height + offsetY)
        
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
        
        NotificationService.sharedInstance.delegate = self
        
        self.setupMiddleButton()
    }
    
    func authorizationChange() {
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
            cameraButton.userInteractionEnabled = false
            
            self.tabBar.addSubview(cameraButton)
            
            cameraActivity = NVActivityIndicatorView(frame: cameraButton.bounds, type: .BallScaleRipple, color: UIColor.whiteColor(), padding: 1.0)
            self.cameraButton.addSubview(cameraActivity)
            cameraActivity.userInteractionEnabled = false
            
            
            
            var hitArea = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 66))
            hitArea.backgroundColor = UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.0)
            var hitAreaFrame = hitArea.frame
            hitAreaFrame.origin.y = self.tabBar.bounds.height - hitAreaFrame.height - 2
            hitAreaFrame.origin.x = self.tabBar.bounds.width/2 - hitAreaFrame.size.width/2
            hitArea.frame = hitAreaFrame
            self.tabBar.addSubview(hitArea)

            hitArea.addTarget(self, action: #selector(presentCamera), forControlEvents: .TouchUpInside)
            hitArea.userInteractionEnabled = true
            
            
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
        deactivateLocation()
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
   

    
    func upload(uploadTask: FIRStorageUploadTask) {

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
    
    
    
    var visibleFrame:CGRect!
    var hiddenFrame:CGRect!
    
    var visibleViewFrame:CGRect!
    var hiddenViewFrame:CGRect!
    
    func setTabBarVisible(_visible:Bool, animated:Bool) {
        
        if visible == _visible {
            return
        }
        visible = _visible

        dispatch_async(dispatch_get_main_queue(), {
 
            if self.visible {
                
                self.tabBar.center = self._center
                self.tabBar.userInteractionEnabled = true
                self.tabBar.frame = self.visibleFrame

            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                self.tabBar.alpha = 1.0

                }, completion: { result in
            })
        } else {
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                self.tabBar.alpha = 0.0
                
                }, completion: { result in
                    self.tabBar.userInteractionEnabled = false
                    self.tabBar.frame = self.hiddenFrame
                    self.tabBar.center = self._hiddenCenter

            })
        }
        })
        
    }
    
}