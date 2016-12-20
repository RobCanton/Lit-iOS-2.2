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
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import Whisper

class MainViewController: UICollectionViewController, UINavigationControllerDelegate, StoreSubscriber, CLLocationManagerDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate {
    
    let transtition = SwiftyExpandingTransition()
    var selectedCellFrame = CGRectZero
    
    var locations = [Location]()
    
    var filteredLocations = [Location]()
    
    let locationManager = CLLocationManager()
    
    let notification = CWStatusBarNotification()
    
    var searchBarActive:Bool = false
    var searchBarBoundsY:CGFloat?
    var searchBar:UISearchBar?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    var activeLocation:Location?
    
    func newState(state: AppState) {
        locations = state.locations
        locations.sortInPlace({
            
            $0.getVisitorsCount() > $1.getVisitorsCount()
            
        })
        
        for i in 0 ..< locations.count {
            let location = locations[i]
            if location.getKey() == state.userState.activeLocationKey {
                locations.removeAtIndex(i)
                locations.insert(location, atIndex: 0)
            }
            
        }

        collectionView?.reloadData()
        
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
    
    var murmur:Murmur?
    func activateLocation(location:Location) {
        activeLocation = location
        murmur = Murmur(title: "You are near \(activeLocation!.getName())")
        murmur!.backgroundColor = accentColor
        murmur!.titleColor = UIColor.whiteColor()
        // Present a permanent status bar message
//        show(whistle: murmur!, action: .Present)
    }
    
    func deactivateLocation() {
        activeLocation = nil
        if let _ = murmur {
            hide(whisperFrom: navigationController!)
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
        collectionView!.decelerationRate = UIScrollViewDecelerationRateFast
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        collectionView!.backgroundColor = UIColor.clearColor()
        
        //self.navigationController?.navigationBar.topItem!.title = mainStore.state.userState.activeCity?.getName()
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 20.0)!]
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barStyle = .Black
        self.navigationController?.navigationBar.translucent = true
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        notification.notificationLabelBackgroundColor = UIColor.blackColor()
        notification.notificationAnimationInStyle = .Top
        notification.notificationAnimationOutStyle = .Top
        
        self.addSearchBar()
        searchBar?.hidden = true
    }
    
    func addSearchBar(){
        if self.searchBar == nil{
            self.searchBarBoundsY = screenStatusBarHeight
            
            self.searchBar = UISearchBar(frame: CGRectMake(0,screenStatusBarHeight, UIScreen.mainScreen().bounds.size.width, 44))
            self.searchBar!.searchBarStyle       = UISearchBarStyle.Minimal
            self.searchBar!.tintColor            = UIColor.whiteColor()
            self.searchBar!.barTintColor         = UIColor.whiteColor()
            self.searchBar!.delegate             = self;
            self.searchBar!.placeholder          = "search here";
            self.searchBar!.setTextColor(UIColor.whiteColor())
        }
        
        if !self.searchBar!.isDescendantOfView(self.view){
            self.view .addSubview(self.searchBar!)
        }
    }
    
    
    // MARK: Search
    func filterContentForSearchText(searchText:String){
        self.filteredLocations = locations.filter({ (location:Location) -> Bool in
            return location.getName().containsIgnoringCase(searchText)
        })
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        // user did type something, check our datasource for text that looks the same
        if searchText.characters.count > 0 {
            // search and reload data source
            self.searchBarActive    = true
            self.filterContentForSearchText(searchText)
            self.collectionView?.contentOffset = CGPoint(x: 0, y: 0)
            self.collectionView?.reloadData()
        }else{
            // if text lenght == 0
            // we will consider the searchbar is not active
            self.searchBarActive = false
            self.collectionView?.reloadData()
        }
        
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self .cancelSearching()
        self.collectionView?.reloadData()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        // we used here to set self.searchBarActive = YES
        // but we'll not do that any more... it made problems
        // it's better to set self.searchBarActive = YES when user typed something
        //self.searchBar!.setShowsCancelButton(true, animated: false)
        
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        // this method is being called when search btn in the keyboard tapped
        // we set searchBarActive = NO
        // but no need to reloadCollectionView
        self.searchBarActive = false
        self.searchBar!.setShowsCancelButton(false, animated: false)
    }
    func cancelSearching(){
        searchBar?.hidden = true
        self.searchBarActive = false
        self.searchBar!.resignFirstResponder()
        self.searchBar!.text = ""
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

extension MainViewController {
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.searchBarActive {
            return filteredLocations.count;
        }
        return locations.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("LocationCell", forIndexPath: indexPath) as! LocationCell
        var location:Location!
        if (searchBarActive) {
            location = filteredLocations[indexPath.item]
        } else {
            location = locations[indexPath.item]
        }
        cell.location = location
        

        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let layout = collectionViewLayout as! UltravisualLayout
        let offset = layout.dragOffset * CGFloat(indexPath.item)
        
        if collectionView.contentOffset.y != offset {
            collectionView.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
        } else {
            var location:Location
            if (searchBarActive) {
                location = filteredLocations[indexPath.item]
                cancelSearching()
            } else {
                location = locations[indexPath.item]
            }
            self.selectedCellFrame = collectionView.convertRect(collectionView.cellForItemAtIndexPath(indexPath)!.frame, toView: collectionView.superview)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewControllerWithIdentifier("LocViewController") as! LocViewController
            controller.location = locations[indexPath.item]
            navigationController?.navigationBar.tintColor = UIColor.whiteColor()
            navigationController?.pushViewController(controller, animated: true)
            
        }
    }
}