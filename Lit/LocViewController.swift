
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



class LocViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UINavigationControllerDelegate {
    
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var userStories = [UserStory]()
    var guests = [String]()
    
    var tableView:UITableView?
    var headerView:UIImageView!
    var footerView:LocationFooterView!
    
    var location: Location!
    
    var returningCell:UserStoryTableViewCell?
    
    var events = [Event]()
    var postKeys = [String]()
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        listenToUserUploads()
        tableView?.userInteractionEnabled = false
        
        if statusBarShouldHide {
            UIView.animateWithDuration(0.3, animations: {
                self.statusBarShouldHide = false
                self.setNeedsStatusBarAppearanceUpdate()
            })
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(handleEnterForeground), name:
            UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    var statusBarShouldHide = false
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        FirebaseService.ref.child("locations/uploads/\(location.getKey())").removeAllObservers()
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableView?.userInteractionEnabled = true
        
        if let tabBar = self.tabBarController as? PopUpTabBarController {
            tabBar.setTabBarVisible(true, animated: true)
        }
        
        if let nav = navigationController as? MasterNavigationController {
            nav.setNavigationBarHidden(false, animated: true)
           nav.delegate = nav
        }
        
        if let sup = self.view.superview {
            for sub in sup.subviews {
                if sub !== self.view && !sub.isKindOfClass(UIImageView) {
                    sub.removeFromSuperview()
                }
            }
        }
        
        if returningCell != nil {
            returningCell!.activate(true)
            returningCell = nil
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func listenToUserUploads() {
        let locRef = FirebaseService.ref.child("locations/uploads/\(location.getKey())")
        locRef.removeAllObservers()
        locRef.queryOrderedByKey().observeEventType(.Value, withBlock: { snapshot in

            var tempDictionary = [String:[String]]()
            var timestamps = [String:Double]()
            for user in snapshot.children {
                
                let userSnap = user as! FIRDataSnapshot
                var postKeys = [String]()
                var timestamp:Double!
                
                for post in userSnap.children {
                    let postSnap = post as! FIRDataSnapshot
                    postKeys.append(postSnap.key)
                    timestamp = postSnap.value! as! Double
                }

                tempDictionary[userSnap.key] = postKeys
                timestamps[userSnap.key] = timestamp

            }
            
            self.crossCheckStories(tempDictionary, timestamps: timestamps)

        })
    }
    
    var storiesDictionary = [String:[String]]()
    
    var shouldDisplayEmptyMyStoryCell = false
    
    func crossCheckStories(tempDictionary:[String:[String]], timestamps:[String:Double]) {
        let uid = mainStore.state.userState.uid
        
        if storiesDictionary[uid] != nil && tempDictionary[uid] == nil {
            shouldDisplayEmptyMyStoryCell = true
        } else {
            shouldDisplayEmptyMyStoryCell = false
        }
        
        if NSDictionary(dictionary: storiesDictionary).isEqualToDictionary(tempDictionary) {
            //print("Stories unchanged. No download required")
            //print("Current: \(storiesDictionary) | Temp: \(tempDictionary)")
        } else {
            storiesDictionary = tempDictionary
            var stories = [UserStory]()
            for (uid, itemKeys) in storiesDictionary {
                let story = UserStory(user_id: uid, postKeys: itemKeys, timestamp: timestamps[uid]!)
                stories.append(story)
            }
            
            stories.sortInPlace({
                return $0 > $1
            })
            
            
            for i in 0..<stories.count {
                let story = stories[i]
                if story.getUserId() == mainStore.state.userState.uid {
                    stories.removeAtIndex(i)
                    stories.insert(story, atIndex: 0)
                }
            }

            self.userStories = stories
        }
        
        for story in self.userStories {
            story.determineState()
        }
        tableView?.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        
        if let sup = self.view.superview {
            for sub in sup.subviews {
                
                if sub !== self.view && !sub.isKindOfClass(UIImageView) {
                    sup.sendSubviewToBack(sub)
                    //sub.removeFromSuperview()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        tableView!.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        
        tableView!.backgroundColor = UIColor.blackColor()
        
        let headerNib = UINib(nibName: "LocationHeaderView", bundle: nil)
        tableView!.registerNib(headerNib, forHeaderFooterViewReuseIdentifier: "headerView")
        
        let footerNib = UINib(nibName: "LocationFooterView", bundle: nil)
        tableView!.registerNib(footerNib, forHeaderFooterViewReuseIdentifier: "footerView")
        
        let footerView = UINib(nibName: "LocationFooterView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! LocationFooterView
        tableView!.tableFooterView = footerView
        
        view.addSubview(tableView!)
        
        
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
        
        LocationService.getLocationDetails(location, completionHandler: { location in
            self.location = location
            if let footer = self.tableView?.tableFooterView as? LocationFooterView {
               footer.descriptionLabel.text = self.location.desc
            }
            self.tableView?.reloadData()
        })
    }
    
    
    
    func handleEnterForeground() {
        for story in self.userStories {
            story.determineState()
        }
        tableView?.reloadData()
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
 
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 190
        }
        if section == 1 && userStories.count == 0 {
            return 0
        }
        if section == 2 {
            return 0
        }
        
        return 34
    }
    
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if section == 0 {
            let cell = tableView.dequeueReusableHeaderFooterViewWithIdentifier("headerView")
            let header = cell as! LocationHeaderView
            header.setLocationDetails(location)
            return cell
        } else if section == 1 {
            let headerView = UINib(nibName: "ListHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! ListHeaderView
            headerView.hidden = false
            headerView.label.text = "RECENT GUESTS"
            return headerView
        } else if section == 2 {
            let headerView = UINib(nibName: "ListHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! ListHeaderView
            headerView.hidden = false
            headerView.label.text = "GUESTS"
            return headerView
        } else if section == 3 {
            let headerView = UINib(nibName: "ListHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! ListHeaderView
            headerView.hidden = false
            headerView.label.text = "INFO"
            return headerView
        }
        return nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 0
        }
        if section == 1 {
            return userStories.count
        } else if section == 2  {
            return 0
        } else if section == 3 {
            return 4
        }
        return 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        switch indexPath.section {
        case 0:
            return 46
        case 1:
            return 76
        case 2:
            return 70
        case 3:
            if indexPath.row == 0 {
                return 42
            } else if indexPath.row == 1 && location.phone != nil {
                return 42
            } else if indexPath.row == 2 && location.email != nil {
                return 42
            } else if indexPath.row == 3 && location.website != nil {
                return 42
            }
            return 0
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
            cell.setUserStory(userStories[indexPath.item], useUsername: false)
            return cell
        } else if indexPath.section == 2 {
            
            
            let cell = tableView.dequeueReusableCellWithIdentifier("UserCell", forIndexPath: indexPath) as! UserViewCell
            cell.setupUser(guests[indexPath.item])
            return cell
        } else if indexPath.section == 3 {
            let cell = tableView.dequeueReusableCellWithIdentifier("InfoCell", forIndexPath: indexPath) as! InfoTableViewCell
            if indexPath.row == 0 {
                cell.type = .FullAddress
                cell.label.text = location.getAddress()
            } else if indexPath.row == 1 {
                cell.type = .Phone
                cell.label.text = location.phone
            } else if indexPath.row == 2 {
                cell.type = .Email
                cell.label.text = location.email
            }  else if indexPath.row == 3 {
                cell.type = .Website
                cell.label.text = location.website
            }
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
            let story = userStories[indexPath.item]
            if story.state == .ContentLoaded {
                presentStory(indexPath)
            } else {
                story.downloadStory()
            }
        }
        else if indexPath.section == 2 {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! UserViewCell
            let controller = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewControllerWithIdentifier("UserProfileViewController") as! UserProfileViewController
            controller.uid = cell.user!.getUserId()
            self.navigationController?.pushViewController(controller, animated: true)
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        } else if indexPath.section == 3 {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! InfoTableViewCell
            switch cell.type {
            case .FullAddress:
                showMap()
                break
            case .Phone:
                promptPhoneCall()
                break
            case .Email:
                promptEmail()
                break
            case .Website:
                promptWebsite()
                break
            default:
                break
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func promptPhoneCall() {
        guard let phoneNumber = location.phone else { return }
        let phoneAlert = UIAlertController(title: "Call \(location.getName())?", message: phoneNumber, preferredStyle: UIAlertControllerStyle.Alert)
        
        phoneAlert.addAction(UIAlertAction(title: "Call", style: .Default, handler: { (action: UIAlertAction!) in
            self.callNumber(phoneNumber)
        }))
        
        phoneAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
            
        }))
        
        presentViewController(phoneAlert, animated: true, completion: nil)
    }
    
    private func callNumber(phoneNumber:String) {
        
        let stringArray = phoneNumber.componentsSeparatedByCharactersInSet(
            NSCharacterSet.decimalDigitCharacterSet().invertedSet)
        let cleanNumber = stringArray.joinWithSeparator("")
        if let phoneCallURL:NSURL = NSURL(string:"tel://\(cleanNumber)") {
            let application:UIApplication = UIApplication.sharedApplication()
            if (application.canOpenURL(phoneCallURL)) {
                application.openURL(phoneCallURL);
            }
        }
    }
    
    func promptEmail() {
        guard let email = location.email else { return }
        let phoneAlert = UIAlertController(title: "Contact \(location.getName())?", message: email, preferredStyle: UIAlertControllerStyle.Alert)
        
        phoneAlert.addAction(UIAlertAction(title: "Email", style: .Default, handler: { (action: UIAlertAction!) in
            self.openEmail(email)
        }))
        
        phoneAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
            
        }))
        
        presentViewController(phoneAlert, animated: true, completion: nil)
    }
    
    func openEmail(email:String) {

        let url = NSURL(string: "mailto:\(email)")
        UIApplication.sharedApplication().openURL(url!)
    }
    
    func promptWebsite() {
        guard let website = location.website else { return }
        let phoneAlert = UIAlertController(title: "Visit \(website)?", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        phoneAlert.addAction(UIAlertAction(title: "Open", style: .Default, handler: { (action: UIAlertAction!) in
            self.openWebsite(website)
        }))
        
        phoneAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
            
        }))
        
        presentViewController(phoneAlert, animated: true, completion: nil)
    }
    
    func openWebsite(website:String) {
        let url = NSURL(string: "http://\(website)")!
        UIApplication.sharedApplication().openURL(url)
    }
    
    func presentStory(indexPath:NSIndexPath) {
        self.selectedIndexPath = indexPath
        
        if let tabBar = self.tabBarController as? PopUpTabBarController {
            tabBar.setTabBarVisible(false, animated: true)
        }
        let pullUpController = WrapperController()
        pullUpController.transitionController = self.transitionController
        pullUpController.tabBarRef   = self.tabBarController! as! PopUpTabBarController
        pullUpController.stories = userStories
//        let presentedViewController: LocationStoriesViewController = LocationStoriesViewController()
//        presentedViewController.tabBarRef   = self.tabBarController! as! PopUpTabBarController
//        presentedViewController.userStories = userStories
//        presentedViewController.location    = location
//        presentedViewController.transitionController = self.transitionController
        let i = NSIndexPath(forItem: indexPath.row, inSection: 0)
        self.transitionController.userInfo = ["destinationIndexPath": i, "initialIndexPath": i]
        
        // This example will push view controller if presenting view controller has navigation controller.
        // Otherwise, present another view controller
        if let navigationController = self.navigationController {
            
            statusBarShouldHide = true
            // Set transitionController as a navigation controller delegate and push.
            

            navigationController.delegate = transitionController
            transitionController.push(viewController: pullUpController, on: self, attached: pullUpController)
            
        }
    }
 
    override func prefersStatusBarHidden() -> Bool {
        return statusBarShouldHide
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
        let x = cell.frame.origin.x + 20
        
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        
        let y = cell.frame.origin.y + 12 + navHeight
        
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
        if !isPresenting {
            if let cell = tableView?.cellForRowAtIndexPath(i) as? UserStoryTableViewCell {
                returningCell?.activate(false)
                returningCell = cell
                returningCell!.deactivate()
            }
        }
        if !isPresenting && !self.tableView!.indexPathsForVisibleRows!.contains(i) {
            self.tableView!.reloadData()
            self.tableView!.scrollToRowAtIndexPath(i, atScrollPosition: .Middle, animated: false)
            self.tableView!.layoutIfNeeded()
        }
    }
}
