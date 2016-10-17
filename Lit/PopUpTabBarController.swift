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

class PopUpTabBarController: UITabBarController, StoreSubscriber, UITabBarControllerDelegate {
    
    let tabBarHeight:CGFloat = 60
    var activeLocation:Location?
    
    var array = [UIView]()
    
    var selectedItem = 0
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
                    // ACTIVE LOCATION SET
                }
            }
        }
        
        messageNotifications()
        socialNotifications()
    }
    
    func messageNotifications() {
        var count = 0
        for conversation in mainStore.state.conversations {
            if !conversation.seen {
                count += 1
            }
        }
        if count > 0 {
            tabBar.items?[1].badgeValue = "\(count)"
        } else {
            tabBar.items?[1].badgeValue = nil
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
            tabBar.items?[2].badgeValue = "\(count)"
        } else {
            tabBar.items?[2].badgeValue = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBarController?.delegate = self
        //self.tabBarController?.tabBar.shadowImage = UIImage()
        self.tabBar.setValue(true, forKey: "_hidesShadow")
        let itemWidth = tabBar.frame.width / CGFloat(tabBar.items!.count)
        for itemIndex in 0...tabBar.items!.count
        {
            let bgView = UIView(frame: CGRectMake(itemWidth * CGFloat(itemIndex), 0, itemWidth, tabBarHeight))
            if itemIndex == 2
            {
                bgView.backgroundColor = UIColor(red: 1, green: 175/255, blue: 0, alpha: 0.5)
                //bgView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.15)
                bgView.alpha = 1.0
            }
            else
            {
                bgView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.15)
                bgView.alpha = 0
            }
            
            tabBar.insertSubview(bgView, atIndex: 0)
            array.append(bgView)
        }
        
        array[0].alpha = 1
        
//        let cameraItem = tabBar.items![2]


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