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

class LocViewController: UIViewController, StoreSubscriber, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, LocationHeaderProtocol, UINavigationControllerDelegate {
    
    var statusBarBG:UIView?
    
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var stories = [Story]()
    var photos = [StoryItem]()
    var guests = [String]()
    
    var tableView:UITableView?
    var detailsView:LocationDetailsView!
    var controlBar:UserProfileControlBar?
    var headerView:LocationHeaderView!
    var eventsBanner:EventsBannerView?
    var eventsBannerTap:UITapGestureRecognizer!
    var footerView:LocationFooterView!
    
    var location: Location!
    override func viewWillAppear(animated: Bool) {
        mainStore.subscribe(self)
        //navigationController?.hidesBarsOnSwipe = true
        print("LocationViewController Subscribed")
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        mainStore.unsubscribe(self)
        //navigationController?.hidesBarsOnSwipe = true
        print("LocationViewController Unsubscribed")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.delegate = self
        if let tabBar = self.tabBarController as? PopUpTabBarController {
            tabBar.setTabBarVisible(true, animated: true)
        }
    }
    
    var events = [Event]()
    
    func newState(state: AppState) {
        print("New State!")
        
    }
    
    func downloadMedia() {
        FirebaseService.downloadStory(location!.getPostKeys(), completionHandler: { items in
            //self.photos = story.reverse()
            self.stories = sortStoryItems(items)
            print("STORY \(self.stories)")
            self.tableView!.reloadData()
        })
    }
    override func viewDidLayoutSubviews() {
        //headerView.setGuests()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = " "
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        detailsView = UINib(nibName: "LocationDetailsView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as? LocationDetailsView
        
        detailsView.frame = CGRectMake(0, 0, self.view.frame.width, detailsView.frame.height)

        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        let slack:CGFloat = 1.0
        let eventsHeight:CGFloat = 0
        let topInset:CGFloat = navHeight + detailsView.frame.height + eventsHeight + slack
        
        
        print("BEFORE : \(detailsView.descriptionLabel.frame.height)")
        let prevHeight = detailsView.descriptionLabel.frame.height
        detailsView.descriptionLabel.text = "Swanky black & gold interior with metallic finishes, plus buzzing music for dancing crowds."
        detailsView.descriptionLabel.sizeToFit()
        detailsView.sizeToFit()
        print("AFTER : \(detailsView.descriptionLabel.frame.height)")
        let difference  = detailsView.descriptionLabel.frame.height
        detailsView.frame = CGRectMake(0, 0, self.view.frame.width, detailsView.frame.height + difference)
        
        
        headerView = UINib(nibName: "LocationHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! LocationHeaderView
        headerView.delegate = self
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: topInset , left: 0, bottom: 200, right: 0)
        layout.itemSize = CGSize(width: screenWidth, height: 80)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        tableView = UITableView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height))
        
        let eventNib = UINib(nibName: "EventTableViewCell", bundle: nil)
        tableView!.registerNib(eventNib, forCellReuseIdentifier: "EventCell")
        
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
        tableView!.parallaxHeader.height = UltravisualLayoutConstants.Cell.featuredHeight
        tableView!.parallaxHeader.mode = .Fill
        tableView!.parallaxHeader.minimumHeight = 0;
        tableView!.separatorColor = UIColor(white: 0.25, alpha: 1.0)
        
        tableView!.backgroundColor = UIColor.blackColor()
        view.addSubview(tableView!)
        
        
        //tableView?.addSubview(detailsView)
        
        footerView = UINib(nibName: "LocationFooterView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! LocationFooterView
        footerView.frame = CGRectMake(0, 0, tableView!.frame.width, 120)
        //collectionView?.registerClass(footerView, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "myFooterView")
        
        statusBarBG = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: navHeight))
        statusBarBG!.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        
        titleLabel = UILabel()
        titleLabel.frame = statusBarBG!.bounds
        titleLabel.frame = CGRectMake(0, screenStatusBarHeight/2, statusBarBG!.bounds.width, headerView.locationTitle.frame.height)
        titleLabel.center = CGPoint(x: statusBarBG!.bounds.width/2, y: statusBarBG!.bounds.height/2 + screenStatusBarHeight/2)
        titleLabel.textAlignment = .Center
        statusBarBG!.addSubview(titleLabel)
        titleLabel.hidden = true
        
        view.addSubview(statusBarBG!)
        headerView.setLocation(location)
        titleLabel.styleLocationTitle(location.getName(), size: 32.0)
        titleLabel.applyShadow(4, opacity: 0.8, height: 4, shouldRasterize: false)
        detailsView.setLocation(location)
        downloadMedia()
        
        FirebaseService.getLocationEvents(location.getKey(), completionHandler: { events in
            if events.count > 0 {
                self.events = events
                self.tableView!.reloadData()
                self.buildEventsBanner()
            }
        })
        
        tableView!.tableFooterView = UIView(frame: CGRectMake(0,0,tableView!.frame.width, 90))
        
        
        guests = location.getVisitors()
        
        
    }
    
    var titleLabel:UILabel!
    
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
            mapController.setLocation(location!)
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
    
    func buildEventsBanner() {
//        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
//        let eventsHeight:CGFloat = 150.0
//        let slack:CGFloat = 1.0
//        let topInset:CGFloat = detailsView.frame.height + eventsHeight + slack
//        
//        eventsBanner = UINib(nibName: "EventsBannerView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as? EventsBannerView
//        eventsBanner!.clipsToBounds = true
//        eventsBanner!.frame = CGRectMake(0,detailsView.frame.height, tableView!.frame.width, eventsHeight)
//        
//        eventsBannerTap = UITapGestureRecognizer(target: self, action: #selector(showEvents))
//        eventsBanner!.addGestureRecognizer(eventsBannerTap)
//        
//        let collectionViewLayout = tableView!.collectionViewLayout as? UICollectionViewFlowLayout
//        
//        collectionViewLayout?.sectionInset = UIEdgeInsets(top: topInset, left: 0, bottom: 200, right: 0)
//        collectionViewLayout?.invalidateLayout()
//        
//        tableView!.addSubview(eventsBanner!)
//        
//        if events.count > 0 {
//            eventsBanner!.event = events[0]
//        }
//        //eventsBanner?.hidden = true

    }
    
    func mediaDeleted() {
        self.photos = [StoryItem]()
        self.tableView!.reloadData()
        downloadMedia()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if events.count > 0 {
                
            } else {
                return 0
            }
        }
        return 34
    }
    
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UINib(nibName: "ListHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! ListHeaderView
        if section == 0 {
            if events.count > 0 {
                headerView.label.text = "Upcoming Events"
                headerView.label.textColor = UIColor.whiteColor()
            } else {
                headerView.label.text = "No Upcoming Events"
                headerView.label.textColor = UIColor.grayColor()
            }
            
        } else if section == 1 {
            headerView.label.text = "Recent Updates"
        } else if section == 2 {
            headerView.label.text = "Guests"
        }
        return headerView
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            if events.count > 0 {
                return 1
            } else { return 0 }
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
            return 134
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
            let cell = tableView.dequeueReusableCellWithIdentifier("EventCell", forIndexPath: indexPath) as! EventTableViewCell
            cell.events = events
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
        if indexPath.section == 1 {
            self.selectedIndexPath = indexPath
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! UserStoryTableViewCell
            
            let presentedViewController: PresentedViewController = PresentedViewController()
            presentedViewController.tabBarRef = self.tabBarController! as! PopUpTabBarController
            presentedViewController.stories = stories
            presentedViewController.transitionController = self.transitionController
            var i = NSIndexPath(forItem: indexPath.row, inSection: 0)
            self.transitionController.userInfo = ["destinationIndexPath": i, "initialIndexPath": i]
            
            // This example will push view controller if presenting view controller has navigation controller.
            // Otherwise, present another view controller
            if let navigationController = self.navigationController {
                
                // Set transitionController as a navigation controller delegate and push.
                navigationController.delegate = transitionController
                transitionController.push(viewController: presentedViewController, on: self, attached: presentedViewController)
                
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

    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let progress = scrollView.parallaxHeader.progress
        headerView.setProgress(progress)
        let titlePoint = headerView.locationTitle.frame.origin
        
        if let _ = titleLabel {
            if titlePoint.y <= titleLabel.frame.origin.y {
                headerView.locationTitle.hidden = true
                titleLabel.hidden = false
                statusBarBG!.backgroundColor = UIColor(white: 0.0, alpha: 1.0)
            } else {
                headerView.locationTitle.hidden = false
                titleLabel.hidden = true
                statusBarBG!.backgroundColor = UIColor(white: 0.0, alpha: 0)
            }
        }
        print(progress)
        if progress > -1 {
            //tableView!.pagingEnabled = true
        } else {
            //tableView!.pagingEnabled = false
        }
        
//        if progress < 0 {
//            //detailsView.alpha = 1 + progress * 1.75
//            let scale = abs(progress)
//            if let _ = controlBar {
//
//            }
//            if scale > 0.60 {
//                let prop = ((scale - 0.60) / 0.40) * 1.15
//                print("prop \(prop)")
//                statusBarBG!.backgroundColor = UIColor(white: 0.0, alpha: prop)
//            } else {
//                statusBarBG!.backgroundColor = UIColor(white: 0.0, alpha: 0)
//            }
//        }
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
        let y = cell.frame.origin.y + margin

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
