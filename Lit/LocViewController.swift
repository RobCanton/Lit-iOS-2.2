
//
//  LocViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-17.
//  Copyright © 2016 Robert Canton. All rights reserved.
//
import UIKit
import Firebase
import ReSwift

var dataSaveMode = false

class LocViewController: UIViewController, StoreSubscriber, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UINavigationControllerDelegate, NSCacheDelegate {
    
    
    
    var statusBarBG:UIView?
    
    var scrollEndHandler:(()->())?
    
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var stories = [Story]()
    var photos = [StoryItem]()
    var guests = [String]()
    
    var tableView:UITableView?
    var detailsView:LocationDetailsView!
    var controlBar:UserProfileControlBar?
    var headerView:LocationTableCell!
    var eventsBanner:EventsBannerView?
    var eventsBannerTap:UITapGestureRecognizer!
    var footerView:LocationFooterView!
    
    var location: Location!
    override func viewWillAppear(animated: Bool) {
        mainStore.subscribe(self)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        mainStore.unsubscribe(self)
        FirebaseService.ref.child("locations/uploads/\(location.getKey())").removeAllObservers()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let tabBar = self.tabBarController as? PopUpTabBarController {
            tabBar.setTabBarVisible(true, animated: true)
        }
        listenToLocationUploads()
        
        if let nav = navigationController as? MasterNavigationController {
           nav.delegate = nav
        }
        
        //reloadStoryCells()
        if let sup = self.view.superview {
            for sub in sup.subviews {
                if sub !== self.view && !sub.isKindOfClass(UIImageView) {
                    sub.removeFromSuperview()

                } else {
                    
                }
            }
        }
        
        
        
    }
    
    var events = [Event]()
    var postKeys = [String]()
    
    func newState(state: AppState) {
        
    }
    
    func getStoryIndex(_story:Story) -> Int? {
        for i in 0..<stories.count {
            let story = stories[i]
            if _story.getAuthorID() == story.getAuthorID() {
                return i
            }
        }
        return nil
    }
    
    func listenToLocationUploads() {
        
        let locRef = FirebaseService.ref.child("locations/uploads/\(location.getKey())")
        locRef.removeAllObservers()
        locRef.observeEventType(.Value, withBlock: { snapshot in
            if snapshot.exists() {
                var postKeys = [String]()
                for post in snapshot.children {
                    postKeys.append(post.key!!)
                }
                self.crossCheckPostKeys(postKeys)
            }
        })
    }
    
    func crossCheckPostKeys(newKeys:[String]) {
        let sortedPosts = postKeys.sort()
        let sortedNewPosts = newKeys.sort()
        
        if sortedPosts == sortedNewPosts {
        } else {
            self.downloadMedia(newKeys)
        }
    }
    
    func downloadMedia(_postKeys:[String]) {
        self.postKeys = _postKeys
        FirebaseService.downloadStory(postKeys, completionHandler: { items in
            self.stories = sortStoryItems(items)
            self.stories.sortInPlace({ $0 > $1 })
            self.tableView!.reloadData()
            if !dataSaveMode {
                self.downloadAllStories()
            }
        })
    }
    
    func downloadAllStories() {
        for story in self.stories {
            downloadStory(story, force: false)
        }
    }
    
    func downloadStory(story:Story, force:Bool) {
        
        if let i = self.getStoryIndex(story) {
            let indexPath = [NSIndexPath(forRow: i, inSection: 1)]
            if story.needsDownload() {
                if force {
                    story.downloadStory({ complete in
                        self.tableView?.reloadRowsAtIndexPaths(indexPath, withRowAnimation: .Automatic)
                    })
                }
            } else {
                story.state = .Loaded
            }
            self.tableView?.reloadRowsAtIndexPaths(indexPath, withRowAnimation: .Automatic)
        }
    }
    
    func reloadStoryCells() {
        
        var indexPaths = [NSIndexPath]()
        for i in 0..<stories.count {
            indexPaths.append(NSIndexPath(forRow: i, inSection: 1))
        }
        
        self.tableView?.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    }
    
    override func viewDidLayoutSubviews() {
        if let sup = self.view.superview {
            for sub in sup.subviews {
                
                if sub !== self.view && !sub.isKindOfClass(UIImageView) {
                    sup.sendSubviewToBack(sub)
                    //sub.removeFromSuperview()
                } else {
                
                }
            }
        }
    }
    
    func cache(cache: NSCache, willEvictObject obj: AnyObject) {
        
        if cache === videoCache {
            // downloadAllStories()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoCache.countLimit = 25
        videoCache.delegate = self
        self.navigationItem.title = location.getName()
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 16.0)!,
             NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        detailsView = UINib(nibName: "LocationDetailsView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as? LocationDetailsView
        
        detailsView.frame = CGRectMake(0, 0, self.view.frame.width, detailsView.frame.height)
        
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        let slack:CGFloat = 1.0
        let eventsHeight:CGFloat = 0
        let topInset:CGFloat = navHeight + detailsView.frame.height + eventsHeight + slack
        
        let prevHeight = detailsView.descriptionLabel.frame.height
        detailsView.descriptionLabel.text = "Swanky black & gold interior with metallic finishes, plus buzzing music for dancing crowds."
        detailsView.descriptionLabel.sizeToFit()
        detailsView.sizeToFit()
        
        let difference  = detailsView.descriptionLabel.frame.height
        detailsView.frame = CGRectMake(0, 0, self.view.frame.width, detailsView.frame.height + difference)
        
        headerView = UINib(nibName: "LocationTableCell", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! LocationTableCell
        
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: topInset , left: 0, bottom: 200, right: 0)
        layout.itemSize = CGSize(width: screenWidth, height: 80)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        tableView = UITableView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height))
        
        let eventNib = UINib(nibName: "InfoTableViewCell", bundle: nil)
        tableView!.registerNib(eventNib, forCellReuseIdentifier: "InfoCell")
        
        let nib = UINib(nibName: "UserStoryTableViewCell", bundle: nil)
        tableView!.registerNib(nib, forCellReuseIdentifier: "UserStoryCell")
        let nib2 = UINib(nibName: "UserViewCell", bundle: nil)
        tableView!.registerNib(nib2, forCellReuseIdentifier: "UserCell")
        tableView!.dataSource = self
        tableView!.delegate = self
        tableView!.bounces = true
        tableView!.pagingEnabled = false
        tableView!.showsVerticalScrollIndicator = false
        tableView!.parallaxHeader.view = headerView
        tableView!.parallaxHeader.height = 190
        tableView!.parallaxHeader.mode = .Bottom
        tableView!.parallaxHeader.minimumHeight = 0;
        tableView!.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        tableView!.decelerationRate = UIScrollViewDecelerationRateFast
        
        tableView!.backgroundColor = UIColor.blackColor()
        view.addSubview(tableView!)
        
        tableView!.tableFooterView = UIView(frame: CGRectMake(0,0,tableView!.frame.width, 160))
        
        statusBarBG = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: navHeight))
        statusBarBG!.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        
        headerView.setCellLocation(location)
        headerView.addressLabel.superview!.hidden = true
        headerView.titleLabel.superview!.hidden = true
        headerView.distanceLabel.superview!.hidden = true
        headerView.guestsCountBubble.hidden = true
        headerView.guestIcon1.hidden = true
        headerView.guestIcon2.hidden = true
        headerView.guestIcon3.hidden = true
        
        let btnName = UIButton()
        btnName.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        
        btnName.addTarget(self, action: #selector(showMap), forControlEvents: .TouchUpInside)
        
        if location.getKey() == mainStore.state.userState.activeLocationKey {
            btnName.titleLabel!.font = UIFont(name: "Avenir-Heavy", size: 11.0)
            btnName.setTitle("Nearby", forState: .Normal)
            btnName.backgroundColor = accentColor
            btnName.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        } else {
            if let distance = location.getDistanceFromUserLastLocation() {
                btnName.titleLabel!.font = UIFont(name: "Avenir-Medium", size: 11.0)
                btnName.setTitle(getDistanceString(distance), forState: .Normal)
                
            } else {
               btnName.hidden = true
            }
        }
        btnName.sizeToFit()
        

        let distanceItem = UIBarButtonItem(customView: btnName)
        
        self.navigationItem.rightBarButtonItem = distanceItem

        
        view.addSubview(statusBarBG!)

        guests = location.getVisitors()
    }
    
    
    func pushUserProfile(uid:String) {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("UserProfileViewController")
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func backTapped() {
    }
    
    func showMap() {
        if let _ = location {
            let mapController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewControllerWithIdentifier("MapViewController") as! MapViewController
            mapController.setMapLocation(location!)
            navigationController?.pushViewController(mapController, animated: true)
        }
    }
    
    func showGuests() {
        if let _ = location {
            let controller = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewControllerWithIdentifier("UsersListViewController") as! UsersListViewController
            controller.showStatusBar = true
            controller.title = "guests"
            controller.setTypeToGuests(location!)
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func showEvents(gesture:UITapGestureRecognizer) {
        if let _ = location {
            let controller = UIStoryboard(name: "EventsViewController", bundle: nil)
                .instantiateViewControllerWithIdentifier("EventsViewController") as! EventsViewController
            controller._events = events
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionFooter:
            let view = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: "myFooterView", forIndexPath: indexPath)
            return view
        default:
            return UICollectionReusableView()
        }
    }
    
    
    func mediaDeleted() {
        self.photos = [StoryItem]()
        self.tableView!.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        if section == 1 && stories.count == 0 {
            return 0
        }
        if section == 2 && guests.count == 0 {
            return 0
        }
        return 34
    }
    
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UINib(nibName: "ListHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! ListHeaderView
        if section == 0 {
            headerView.hidden = true
//            if events.count > 0 {
//                headerView.label.text = ""
//                headerView.label.textColor = UIColor.whiteColor()
//            } else {
//                headerView.label.text = "No Upcoming Events"
//                headerView.label.textColor = UIColor.grayColor()
//            }
            
        } else if section == 1 {
            headerView.hidden = false
            headerView.label.text = "Recent Updates"
        } else if section == 2 {
            headerView.hidden = false
            headerView.label.text = "Guests"
        }
        return headerView
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        }
        if section == 1 {
            return stories.count
        } else if section == 2  {
            return guests.count
        }
        return 0
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        switch indexPath.section {
        case 0:
            return 46
        case 1:
            return 80
        case 2:
            return 64
        default:
            return 64
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("InfoCell", forIndexPath: indexPath) as! InfoTableViewCell
            if indexPath.row == 0 {
               cell.label.text = ""
            }
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("UserStoryCell", forIndexPath: indexPath) as! UserStoryTableViewCell
            cell.setStory(stories[indexPath.item])
            return cell
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCellWithIdentifier("UserCell", forIndexPath: indexPath) as! UserViewCell
            cell.setupUser(guests[indexPath.item])
            return cell
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("UserCell", forIndexPath: indexPath)
        return cell
    }
    
    let transitionController: TransitionController = TransitionController()
    var selectedIndexPath: NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            showMap()
        } else if indexPath.section == 1 {
            let story = stories[indexPath.item]
            if story.state == .Loaded {
                presentStory(indexPath)
            } else {
                downloadStory(story, force: true)
            }
            
        }
        else if indexPath.section == 2 {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! UserViewCell
            if let user = cell.user {
                let controller = UIStoryboard(name: "Main", bundle: nil)
                    .instantiateViewControllerWithIdentifier("UserProfileViewController") as! UserProfileViewController
                controller.user = user
                self.navigationController?.pushViewController(controller, animated: true)
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func presentStory(indexPath:NSIndexPath) {
        self.selectedIndexPath = indexPath
        
        let presentedViewController: PresentedViewController = PresentedViewController()
        presentedViewController.tabBarRef = self.tabBarController! as! PopUpTabBarController
        presentedViewController.stories = stories
        presentedViewController.transitionController = self.transitionController
        let i = NSIndexPath(forItem: indexPath.row, inSection: 0)
        self.transitionController.userInfo = ["destinationIndexPath": i, "initialIndexPath": i]
        
        // This example will push view controller if presenting view controller has navigation controller.
        // Otherwise, present another view controller
        if let navigationController = self.navigationController {
            
            // Set transitionController as a navigation controller delegate and push.
            navigationController.delegate = transitionController
            transitionController.push(viewController: presentedViewController, on: self, attached: presentedViewController)
            
        }
    }
    
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let progress = scrollView.parallaxHeader.progress
        /*if progress < -0.75 {
            statusBarBG!.backgroundColor = UIColor(white: 0.0, alpha: 1.0)
        } else {
            statusBarBG!.backgroundColor = UIColor(white: 0.0, alpha: 0)
        }*/
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        print("DID END SHOULD CALL")
        scrollEndHandler?()
    }
    
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

extension LocViewController: View2ViewTransitionPresenting {
    
    func initialFrame(userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        
        guard let indexPath: NSIndexPath = userInfo?["initialIndexPath"] as? NSIndexPath else {
            return CGRect.zero
        }
        var i = NSIndexPath(forRow: indexPath.item, inSection: 1)
        let cell: UserStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(i)! as! UserStoryTableViewCell
        let image_frame = cell.contentImageView.frame
        let image_height = image_frame.height
        let margin = (cell.frame.height - image_height) / 2
        let x = cell.frame.origin.x + margin
        
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        
        let y = cell.frame.origin.y + margin + navHeight
        
        let rect = CGRectMake(x,y,image_height, image_height)
        return self.tableView!.convertRect(rect, toView: self.tableView!.superview)
    }
    
    func initialView(userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: NSIndexPath = userInfo!["initialIndexPath"] as! NSIndexPath
        var i = NSIndexPath(forRow: indexPath.item, inSection: 1)
        let cell: UserStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(i)! as! UserStoryTableViewCell
        
        return cell.contentImageView
    }
    
    func prepareInitialView(userInfo: [String : AnyObject]?, isPresenting: Bool) {
        
        let indexPath: NSIndexPath = userInfo!["initialIndexPath"] as! NSIndexPath
        var i = NSIndexPath(forRow: indexPath.item, inSection: 1)
        if !isPresenting && !self.tableView!.indexPathsForVisibleRows!.contains(i) {
            self.tableView!.reloadData()
            self.tableView!.scrollToRowAtIndexPath(i, atScrollPosition: .Middle, animated: false)
            self.tableView!.layoutIfNeeded()
        }
    }
}
