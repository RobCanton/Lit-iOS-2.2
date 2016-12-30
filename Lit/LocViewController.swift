
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

class LocViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UINavigationControllerDelegate, NSCacheDelegate {
    
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var stories = [Story]()
    var guests = [String]()
    
    var tableView:UITableView?
    var controlBar:UserProfileControlBar?
    var headerView:UIImageView!
    var footerView:LocationFooterView!
    
    var location: Location!
    override func viewWillAppear(animated: Bool) {
        listenToLocationUploads()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        FirebaseService.ref.child("locations/uploads/\(location.getKey())").removeAllObservers()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let tabBar = self.tabBarController as? PopUpTabBarController {
            tabBar.setTabBarVisible(true, animated: true)
        }
        
        
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
            [NSFontAttributeName: UIFont(name: "AvenirNext-DemiBold", size: 16.0)!,
             NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        let slack:CGFloat = 1.0
        let eventsHeight:CGFloat = 0
        let topInset:CGFloat = navHeight + eventsHeight + slack
        
        
        headerView = UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 190))
        headerView.contentMode = .ScaleAspectFill
        headerView.clipsToBounds = true
        
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
        tableView!.parallaxHeader.height = headerView.frame.height
        tableView!.parallaxHeader.mode = .Bottom
        tableView!.parallaxHeader.minimumHeight = 0;
        tableView!.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        
        tableView!.backgroundColor = UIColor.blackColor()
        view.addSubview(tableView!)
        
        tableView!.tableFooterView = UIView(frame: CGRectMake(0,0,tableView!.frame.width, 160))
        
//        headerView.setCellLocation(location)
//        headerView.addressLabel.superview!.hidden = true
//        headerView.titleLabel.superview!.hidden = true
//        headerView.distanceLabel.superview!.hidden = true
//        headerView.guestsCountBubble.hidden = true
//        headerView.guestIcon1.hidden = true
//        headerView.guestIcon2.hidden = true
//        headerView.guestIcon3.hidden = true
        
        loadImageUsingCacheWithURL(location.getImageURL(), completion: { image, fromCache in
            self.headerView.image = image
        })
        
        let btnName = UIButton()
        btnName.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        
        btnName.addTarget(self, action: #selector(showMap), forControlEvents: .TouchUpInside)
        
        if location.getKey() == mainStore.state.userState.activeLocationKey {
            btnName.titleLabel!.font = UIFont(name: "Avenir-Heavy", size: 11.0)
            btnName.setTitle("Nearby", forState: .Normal)
            btnName.backgroundColor = accentColor
            btnName.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        } else {
            if let distance = location.getDistance() {
                btnName.titleLabel!.font = UIFont(name: "Avenir-Medium", size: 11.0)
                btnName.setTitle(getDistanceString(distance), forState: .Normal)
                
            } else {
               btnName.hidden = true
            }
        }
        btnName.sizeToFit()
        btnName.layer.cornerRadius = 2.0
        btnName.clipsToBounds = true
        

        let distanceItem = UIBarButtonItem(customView: btnName)
        
        self.navigationItem.rightBarButtonItem = distanceItem
        
        guests = location.getVisitors()
    }
    
    
    func pushUserProfile(uid:String) {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("UserProfileViewController")
        navigationController?.pushViewController(controller, animated: true)
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
            headerView.label.text = "RECENT ACTIVITY"
        } else if section == 2 {
            headerView.hidden = false
            headerView.label.text = "GUESTS"
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
                controller.uid = cell.user!.getUserId()
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
        let i = NSIndexPath(forRow: indexPath.item, inSection: 1)
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
        let i = NSIndexPath(forRow: indexPath.item, inSection: 1)
        let cell: UserStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(i)! as! UserStoryTableViewCell
        
        return cell.contentImageView
    }
    
    func prepareInitialView(userInfo: [String : AnyObject]?, isPresenting: Bool) {
        
        let indexPath: NSIndexPath = userInfo!["initialIndexPath"] as! NSIndexPath
        let i = NSIndexPath(forRow: indexPath.item, inSection: 1)
        if !isPresenting && !self.tableView!.indexPathsForVisibleRows!.contains(i) {
            self.tableView!.reloadData()
            self.tableView!.scrollToRowAtIndexPath(i, atScrollPosition: .Middle, animated: false)
            self.tableView!.layoutIfNeeded()
        }
    }
}
