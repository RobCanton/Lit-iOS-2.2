//
//  MainViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
////

import UIKit
import ReSwift
import BRYXBanner
import CoreLocation
import LNPopupController
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit

class MainViewController: UICollectionViewController, StoreSubscriber, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    var locations = [Location]()
    
    var filteredLocations = [Location]()
    
    let locationManager = CLLocationManager()
    
    let notification = CWStatusBarNotification()
    

    
    @IBAction func nearMeTapped(sender: UIBarButtonItem) {
        
        FirebaseService.signOut()
    
        
    }
    @IBOutlet weak var nearMeButton: UIBarButtonItem!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self, selector: { state in
            state.locations
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func newState(state: [Location]?) {
        print("MainViewController: New State")
        if state != nil{
            locations = state!
            locations.sortInPlace({ $0.getVisitorsCount() > $1.getVisitorsCount() })
        }

        collectionView?.reloadData()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pictureRequest = FBSDKGraphRequest(graphPath: "me/picture?type=large&redirect=false", parameters: nil)
        pictureRequest.startWithCompletionHandler({
            (connection, result, error: NSError!) -> Void in
            if error == nil {
                print("\(result)")
            } else {
                print("\(error)")
            }
        })
        
        
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
        collectionView!.decelerationRate = UIScrollViewDecelerationRateFast
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        collectionView!.backgroundColor = UIColor.clearColor()
        
        self.navigationController?.navigationBar.topItem!.title = mainStore.state.userState.activeCity?.getName()
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Book", size: 20.0)!]
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.barStyle = .BlackTranslucent
        
        //locationManager.startUpdatingLocation()
        
        notification.notificationLabelBackgroundColor = UIColor.blackColor()
        notification.notificationAnimationInStyle = .Top
        notification.notificationAnimationOutStyle = .Top
    }
    
    
    
}

extension MainViewController {
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locations.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("LocationCell", forIndexPath: indexPath) as! LocationCell
        let location = locations[indexPath.item]
        cell.location = location
        

        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let layout = collectionViewLayout as! UltravisualLayout
        let offset = layout.dragOffset * CGFloat(indexPath.item)
        
        if collectionView.contentOffset.y != offset {
            collectionView.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
        } else {

            mainStore.dispatch(ViewLocationDetail(locationKey: locations[indexPath.item].getKey()))
            mainStore.unsubscribe(self)
            let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LocationViewController")
            navigationController?.navigationBar.tintColor = UIColor.whiteColor()
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
}