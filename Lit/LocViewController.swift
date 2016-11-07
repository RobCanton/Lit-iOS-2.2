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
import ARNTransitionAnimator

class LocViewController: UIViewController, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, LocationHeaderProtocol, ARNImageTransitionZoomable, ZoomProtocol, LocationDetailsProtocol {
    
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

        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        let slack:CGFloat = 1.0
        let controlBarHeight:CGFloat = navHeight
        let eventsHeight:CGFloat = 0
        let topInset:CGFloat = navHeight + eventsHeight + slack
        
        headerView = UINib(nibName: "LocationHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! LocationHeaderView
        headerView.delegate = self
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: topInset, left: 0, bottom: 200, right: 0)
        layout.itemSize = CGSize(width: screenWidth/3, height: screenWidth/3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height), collectionViewLayout: layout)
        
        let nib = UINib(nibName: "PhotoCell", bundle: nil)
        collectionView!.registerNib(nib, forCellWithReuseIdentifier: cellIdentifier)
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.bounces = true
        collectionView!.pagingEnabled = true
        collectionView!.showsVerticalScrollIndicator = false
        collectionView!.parallaxHeader.view = headerView
        collectionView!.parallaxHeader.height = UltravisualLayoutConstants.Cell.featuredHeight
        collectionView!.parallaxHeader.mode = .Fill
        collectionView!.parallaxHeader.minimumHeight = 0;
        
        collectionView!.backgroundColor = UIColor.blackColor()
        view.addSubview(collectionView!)
        
        detailsView = UINib(nibName: "LocationDetailsView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as? LocationDetailsView
        detailsView.frame = CGRectMake(0, 0, collectionView!.frame.width, navHeight)
        detailsView.delegate = self
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
        let topInset:CGFloat = navHeight + eventsHeight + slack
        
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
        
        if photos.count > 12 {
            return CGSize(width: screenWidth/4, height: screenWidth/4);
        }
        return CGSize(width: screenWidth/3, height: screenWidth/3);
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
            detailsView.alpha = 1 + progress * 1.75
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
    
    var selectedImageView : UIImageView?
    var selectedIndexPath: NSIndexPath?
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PhotoCell
        selectedImageView = cell.imageView
        selectedIndexPath = indexPath
        
        if let nav = navigationController as? ARNImageTransitionNavigationController {
            nav.doZoomTransition = true
        }

        showInteractive()
    }
    
    var animator : ARNTransitionAnimator?
    
    
    var isModeModal = false
    
    var controller:ModalViewController!
    func showInteractive() {
        let storyboard = UIStoryboard(name: "ModalViewController", bundle: nil)
        controller = storyboard.instantiateViewControllerWithIdentifier("ModalViewController") as! ModalViewController
        controller.item = self.photos[self.selectedIndexPath!.item]
        controller.delegate = self
        
        let operationType: ARNTransitionAnimatorOperation = isModeModal ? .Present : .Push
        let animator = ARNTransitionAnimator(operationType: operationType, fromVC: self, toVC: controller)
        
        animator.presentationBeforeHandler = { [weak self] containerView, transitionContext in
            containerView.addSubview(self!.controller.view)
            
            self!.controller.view.layoutIfNeeded()
            
            let sourceImageView = self!.createTransitionImageView()
            let destinationImageView = self!.controller.createTransitionImageView()
            
            containerView.addSubview(sourceImageView)
            
            self!.controller.presentationBeforeAction()
            
            self!.controller.view.alpha = 0.0
            
            animator.presentationAnimationHandler = { containerView, percentComplete in
                sourceImageView.frame = destinationImageView.frame
                self!.controller.view.alpha = 1.0
            }
            
            animator.presentationCompletionHandler = { containerView, completeTransition in
                sourceImageView.removeFromSuperview()
                self!.presentationCompletionAction(completeTransition)
                self!.controller.presentationCompletionAction(completeTransition)
            }
        }
        
        animator.dismissalBeforeHandler = { [weak self] containerView, transitionContext in
            if case .Dismiss = self!.animator!.interactiveType {
                containerView.addSubview(self!.navigationController!.view)
            } else {
                containerView.addSubview(self!.view)
            }
            containerView.bringSubviewToFront(self!.controller.view)
            
            let sourceImageView = self!.controller.createTransitionImageView()
            let destinationImageView = self!.createTransitionImageView()
            containerView.addSubview(sourceImageView)
            
            let sourceFrame = sourceImageView.frame;
            let destFrame = destinationImageView.frame;
            
            self!.controller.dismissalBeforeAction()
            
            animator.dismissalCancelAnimationHandler = { (containerView: UIView) in
                sourceImageView.frame = sourceFrame
                self!.controller.view.alpha = 1.0
            }
            
            animator.dismissalAnimationHandler = { containerView, percentComplete in
                if percentComplete < -0.05 { return }
                let frame = CGRectMake(
                    destFrame.origin.x - (destFrame.origin.x - sourceFrame.origin.x) * (1 - percentComplete),
                    destFrame.origin.y - (destFrame.origin.y - sourceFrame.origin.y) * (1 - percentComplete),
                    destFrame.size.width + (sourceFrame.size.width - destFrame.size.width) * (1 - percentComplete),
                    destFrame.size.height + (sourceFrame.size.height - destFrame.size.height) * (1 - percentComplete)
                )
                sourceImageView.frame = frame
                self!.controller.view.alpha = 1.0 - (1.0 * percentComplete)
            }
            
            animator.dismissalCompletionHandler = { containerView, completeTransition in
                self!.dismissalCompletionAction(completeTransition)
                self!.controller.dismissalCompletionAction(completeTransition)
                sourceImageView.removeFromSuperview()
            }
        }
        
        self.animator = animator
        
        if isModeModal {
            self.animator!.interactiveType = .Dismiss
            controller.transitioningDelegate = self.animator
            self.presentViewController(controller, animated: true, completion: nil)
        } else {
            self.animator!.interactiveType = .Pop
            if let _nav = self.navigationController as? ARNImageTransitionNavigationController {
                _nav.interactiveAnimator = self.animator!
            }
            controller.animatorRef = self.animator!
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func Deanimate(){
        self.animator?.interactiveType = .None
    }
    
    func Reanimate(){
        //self.animator?.interactiveType = .Push
    }
    
    func createTransitionImageView() -> UIImageView {
        
        let imageView = UIImageView()
        imageView.loadImageUsingCacheWithURLString(photos[selectedIndexPath!.item].getDownloadUrl()!.absoluteString, completion: { result in})
        imageView.contentMode = self.selectedImageView!.contentMode
        imageView.clipsToBounds = true
        imageView.userInteractionEnabled = false
        let attr = collectionView!.layoutAttributesForItemAtIndexPath(selectedIndexPath!)
        let size = getItemSize(selectedIndexPath!)
        
        let offset = collectionView!.contentOffset.y
        imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let imagePoint = CGPoint(x: attr!.center.x, y: attr!.center.y - offset)
        imageView.center = imagePoint //self.parentViewController!.view.convertPoint(imagePoint, fromView: self.view)

        return imageView
    }
    
    func presentationCompletionAction(completeTransition: Bool) {
        self.selectedImageView?.hidden = true
    }
    
    func dismissalCompletionAction(completeTransition: Bool) {
        self.selectedImageView?.hidden = false
        if completeTransition {
            if let tabBar = self.tabBarController as? PopUpTabBarController {
                tabBar.setTabBarVisible(true, animated: true)
            }
        }
    }
    
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
