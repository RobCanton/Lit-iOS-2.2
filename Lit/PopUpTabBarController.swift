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

class PopUpTabBarController: UITabBarController, StoreSubscriber, UITabBarControllerDelegate, GPSServiceDelegate {
    
    var activeLocation:Location?
    
    var visible = true
    
    let tabBarHeight:CGFloat = 54
    
    var array = [UIView]()
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
    
    var messageView:MessageView?
    func activateLocation(location:Location) {
        activeLocation = location
        print("ACTIVE LOCATION: \(activeLocation!.getKey())")
        
        messageView = MessageView.viewFromNib(layout: .MessageView)
        
        // Add a drop shadow.
        messageView!.configureDropShadow()
        
        // Set message title, body, and icon. Here, we're overriding the default warning
        // image with an emoji character.
        let iconText = ["🤔"].sm_random()!
        messageView!.configureContent(title: "\(activeLocation!.getName())", body: "You are here. Share a photo!", iconText: iconText)
        
        var config = SwiftMessages.defaultConfig
        config.duration = .Forever
        config.presentationContext = .Window(windowLevel: UIWindowLevelNormal)
        SwiftMessages.show(config: config, view: messageView!)
      
    }
    
    func deactivateLocation() {
        activeLocation = nil
        array[2].alpha = 0.0
        
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
            tabBar.items?[1].badgeValue = "\(count)"
        } else {
            tabBar.items?[1].badgeValue = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        tabBarController?.delegate = self
        tabBar.backgroundImage = UIImage()
        tabBar.backgroundColor = UIColor.clearColor()
        tabBar.shadowImage = UIImage()
        
        
        self.tabBar.setValue(true, forKey: "_hidesShadow")
        let itemWidth = tabBar.frame.width / CGFloat(tabBar.items!.count)
        for itemIndex in 0...tabBar.items!.count
        {
            let bgView = UIView(frame: CGRectMake(itemWidth * CGFloat(itemIndex), 0, itemWidth, tabBarHeight))
            if itemIndex == 2
            {
                bgView.backgroundColor = accentColor
                //bgView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.15)
                bgView.alpha = 0
            }
            else
            {
                bgView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1)
                bgView.alpha = 0
            }
            
            tabBar.insertSubview(bgView, atIndex: 0)
            array.append(bgView)
        }
        
        array[0].alpha = 1
        
        let bgView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        bgView.frame = CGRectMake(0,0,self.view.frame.width,tabBarHeight)
        
        tabBar.addSubview(bgView)
        tabBar.sendSubviewToBack(bgView)
        
        GPSService.sharedInstance.delegate = self
        GPSService.sharedInstance.startUpdatingLocation()
    }
    
    override func viewWillLayoutSubviews() {
        var tabFrame:CGRect = self.tabBar.frame
        tabFrame.size.height = tabBarHeight
        tabFrame.origin.y = self.view.frame.size.height - tabBarHeight;
        self.tabBar.frame = tabFrame
    }
    
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        
        let itemTag = item.tag
        highlightItem(itemTag)
    }
    
    internal func highlightItem(itemTag:Int)
    {

        if itemTag == 2
        {
            
            self.performSegueWithIdentifier("toCamera", sender: self)
            
        } else {
            let prevItem = array[selectedItem]
            selectedItem = itemTag
            UIView.animateWithDuration(0.15, animations: {
                prevItem.alpha = 0
                self.array[itemTag].alpha = 1.0
            })
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destinationViewController = segue.destinationViewController as? CameraViewController {
            destinationViewController.transitioningDelegate = self
            destinationViewController.interactor = interactor
        }
    }
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        print(selectedIndex)
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
        let offsetY = (visible ? -height : height)
        
        UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseOut, animations: {
            self.tabBar.frame = CGRectOffset(frame, 0, offsetY)
            self.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height + offsetY)
            self.view.setNeedsDisplay()
            self.view.layoutIfNeeded()
            }, completion: { result in })
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