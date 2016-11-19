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

class LocViewController: UIViewController, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, LocationHeaderProtocol, UINavigationControllerDelegate {
    
    var statusBarBG:UIView?
    
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var photos = [StoryItem]()
    var collectionView:UICollectionView?
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
        FirebaseService.downloadStory(location!.getPostKeys(), completionHandler: { story in
            self.photos = story.reverse()
            self.collectionView!.reloadData()
        })
    }
    override func viewDidLayoutSubviews() {
        headerView.setGuests()
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
        layout.itemSize = CGSize(width: screenWidth / 2, height: screenWidth / 2)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height), collectionViewLayout: layout)
        
        let nib = UINib(nibName: "PhotoCell", bundle: nil)
        collectionView!.registerNib(nib, forCellWithReuseIdentifier: cellIdentifier)
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.bounces = true
        collectionView!.pagingEnabled = false
        collectionView!.showsVerticalScrollIndicator = false
        collectionView!.parallaxHeader.view = headerView
        collectionView!.parallaxHeader.height = UltravisualLayoutConstants.Cell.featuredHeight
        collectionView!.parallaxHeader.mode = .Fill
        collectionView!.parallaxHeader.minimumHeight = 0;
        
        collectionView!.backgroundColor = UIColor.blackColor()
        view.addSubview(collectionView!)
        
        
        collectionView?.addSubview(detailsView)
        
        footerView = UINib(nibName: "LocationFooterView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! LocationFooterView
        footerView.frame = CGRectMake(0, 0, collectionView!.frame.width, 120)
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
        detailsView.setLocation(location)
        downloadMedia()
        
        FirebaseService.getLocationEvents(location.getKey(), completionHandler: { events in
            if events.count > 0 {
                self.events = events
                self.buildEventsBanner()
            }
        })
        
        
        
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
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        let eventsHeight:CGFloat = 150.0
        let slack:CGFloat = 1.0
        let topInset:CGFloat = detailsView.frame.height + eventsHeight + slack
        
        eventsBanner = UINib(nibName: "EventsBannerView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as? EventsBannerView
        eventsBanner!.clipsToBounds = true
        eventsBanner!.frame = CGRectMake(0,detailsView.frame.height, collectionView!.frame.width, eventsHeight)
        
        eventsBannerTap = UITapGestureRecognizer(target: self, action: #selector(showEvents))
        eventsBanner!.addGestureRecognizer(eventsBannerTap)
        
        let collectionViewLayout = collectionView!.collectionViewLayout as? UICollectionViewFlowLayout
        
        collectionViewLayout?.sectionInset = UIEdgeInsets(top: topInset, left: 0, bottom: 200, right: 0)
        collectionViewLayout?.invalidateLayout()
        
        collectionView!.addSubview(eventsBanner!)
        
        if events.count > 0 {
            eventsBanner!.event = events[0]
        }
        //eventsBanner?.hidden = true

    }
    
    func mediaDeleted() {
        self.photos = [StoryItem]()
        self.collectionView!.reloadData()
        downloadMedia()
    }
    

    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PhotoCell
        
        cell.setPhoto(photos[indexPath.item])
        
        
        return cell
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return getItemSize(indexPath)
    }
    
    func getItemSize(indexPath:NSIndexPath) -> CGSize {
        
//        if photos.count > 12 {
//            return CGSize(width: screenWidth/4, height: screenWidth/4);
//        }
        return CGSize(width: screenWidth / 2, height: screenWidth / 2);
    }

    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let progress = scrollView.parallaxHeader.progress
        headerView.setProgress(progress)
        let titlePoint = headerView.locationTitle.frame.origin
        
        if let _ = titleLabel {
            if titlePoint.y <= titleLabel.frame.origin.y {
                headerView.locationTitle.hidden = true
                titleLabel.hidden = false
            } else {
                headerView.locationTitle.hidden = false
                titleLabel.hidden = true
            }
        }
        
        if progress < 0 {
            //detailsView.alpha = 1 + progress * 1.75
            let scale = abs(progress)
            if let _ = controlBar {

            }
            if scale > 0.80 {
                let prop = ((scale - 0.80) / 0.20) * 1.15
                print("prop \(prop)")
                statusBarBG!.backgroundColor = UIColor(white: 0.0, alpha: prop)
            } else {
                statusBarBG!.backgroundColor = UIColor(white: 0.0, alpha: 0)
            }
        }
    }

    let transitionController: TransitionController = TransitionController()
    var selectedIndexPath: NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedIndexPath = indexPath
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        let presentedViewController: PresentedViewController = PresentedViewController()
        presentedViewController.tabBarRef = self.tabBarController! as! PopUpTabBarController
        presentedViewController.photos = photos
        presentedViewController.transitionController = self.transitionController
        self.transitionController.userInfo = ["destinationIndexPath": indexPath, "initialIndexPath": indexPath]
        
        // This example will push view controller if presenting view controller has navigation controller.
        // Otherwise, present another view controller
        if let navigationController = self.navigationController {
            
            // Set transitionController as a navigation controller delegate and push.
            navigationController.delegate = transitionController
            transitionController.push(viewController: presentedViewController, on: self, attached: presentedViewController)
            
        } else {
        }
        
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        
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
        
        guard let indexPath: NSIndexPath = userInfo?["initialIndexPath"] as? NSIndexPath, attributes: UICollectionViewLayoutAttributes = self.collectionView!.layoutAttributesForItemAtIndexPath(indexPath) else {
            return CGRect.zero
        }
        
        let rect = CGRectMake(attributes.frame.origin.x,attributes.frame.origin.y,attributes.frame.width, attributes.frame.width * 0.86666666667)
        return self.collectionView!.convertRect(rect, toView: self.collectionView!.superview)
    }
    
    func initialView(userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: NSIndexPath = userInfo!["initialIndexPath"] as! NSIndexPath
        let cell: PhotoCell = self.collectionView!.cellForItemAtIndexPath(indexPath)! as! PhotoCell
        
        return cell.imageView
    }
    
    func prepareInitialView(userInfo: [String : AnyObject]?, isPresenting: Bool) {
        
        let indexPath: NSIndexPath = userInfo!["initialIndexPath"] as! NSIndexPath
        
        if !isPresenting && !self.collectionView!.indexPathsForVisibleItems().contains(indexPath) {
            self.collectionView!.reloadData()
            self.collectionView!.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredVertically, animated: false)
            self.collectionView!.layoutIfNeeded()
        }
    }
}
