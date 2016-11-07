//
//  ActivityFeedViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift
import SwiftyJSON
import ARNTransitionAnimator

class ActivityFeedViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, ARNImageTransitionZoomable, ZoomProtocol {
 
    
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var searchBarActive:Bool = false
    var searchBarBoundsY:CGFloat?
    var searchBar:UISearchBar?
    
    var photos = [StoryItem]()
    var collectionView:UICollectionView!
    
    var statusBarBG:UIView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let topInset = navigationController!.navigationBar.frame.height
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Book", size: 20.0)!]
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barStyle = .Black
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        view.backgroundColor = UIColor.blackColor()

        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: topInset + screenStatusBarHeight, left: 0, bottom: 0, right: 0)
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
        collectionView!.showsVerticalScrollIndicator = true
        
        collectionView!.backgroundColor = UIColor.blackColor()
        view.addSubview(collectionView!)
        
        statusBarBG = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: topInset + screenStatusBarHeight))
        statusBarBG.backgroundColor = UIColor(white: 0.0, alpha: 1.0)
        view.addSubview(statusBarBG)
        
        self.addSearchBar()
        
        let coverTapView = UIView(frame: searchBar!.frame)
        coverTapView.backgroundColor = UIColor.clearColor()
        view.addSubview(coverTapView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(toSearchView))
        coverTapView.addGestureRecognizer(tap)
        
        
        

    }
    
    func addSearchBar(){
        if self.searchBar == nil{
            self.searchBarBoundsY = screenStatusBarHeight
            
            self.searchBar = UISearchBar(frame: CGRectMake(0,screenStatusBarHeight, UIScreen.mainScreen().bounds.size.width, navigationController!.navigationBar.frame.height))
            self.searchBar!.searchBarStyle       = UISearchBarStyle.Minimal
            self.searchBar!.tintColor            = UIColor.whiteColor()
            self.searchBar!.barTintColor         = UIColor(white: 0.05, alpha: 1.0)
            
            self.searchBar!.placeholder          = "search here";
            self.searchBar!.sizeToFit()
            self.searchBar!.setTextColor(UIColor.whiteColor())
            self.searchBar!.userInteractionEnabled = false

        }
        
        if !self.searchBar!.isDescendantOfView(self.view){
            
            self.view.addSubview(self.searchBar!)
        }
    }
    
    func toSearchView(gesture:UITapGestureRecognizer) {
        self.performSegueWithIdentifier("toSearchView", sender: self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        requestActivityFeed()
    }
    
    func requestActivityFeed() {
        if let location = GPSService.sharedInstance.lastLocation {
            let uid = mainStore.state.userState.uid
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            
            let url = NSURL(string: "\(apiURL)/activityfeed/\(uid)/\(lat)/\(lon)")
            
            let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else {
                    print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                    self.extractFeedFromJSON(data!)
                }
            }
            
            task.resume()
        }
    }
    
    func extractFeedFromJSON(data:NSData) {
        var postKeys = [String]()
        let json = JSON(data: data)
        if json["activity"].exists() {
            //If json is .Dictionary
            for (_,subJson):(String, JSON) in json["activity"] {
                //Do something you want
                let item = subJson.stringValue
                postKeys.append(item)
            }
        }
        downloadMedia(postKeys)
    }
    
    func downloadMedia(postKeys:[String]) {
        FirebaseService.downloadStory(postKeys, completionHandler: { story in
            self.photos = story.reverse()
            self.collectionView!.reloadData()
        })
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
        return CGSize(width: screenWidth/3, height: screenWidth/3);
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
            
            if let tabBar = self!.tabBarController as? PopUpTabBarController {
                tabBar.setTabBarVisible(false, animated: true)
            }
            
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
    
    func mediaDeleted() {
        self.photos = [StoryItem]()
        self.collectionView!.reloadData()
        requestActivityFeed()
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