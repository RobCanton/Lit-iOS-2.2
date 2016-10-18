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

class LocViewController: UIViewController, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, HeaderProtocol, ARNImageTransitionZoomable, ZoomProtocol {
    
    var statusBarBG:UIView?
    
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var photos = [StoryItem]()
    var collectionView:UICollectionView?
    var controlBar:UserProfileControlBar?
    var headerView:LocationHeaderView!
    
    var location: Location?
        {
        didSet {
            
            downloadMedia()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        mainStore.subscribe(self)
        navigationController?.setNavigationBarHidden(true, animated: false)
        //navigationController?.hidesBarsOnSwipe = true
        print("LocationViewController Subscribed")
    }
    
    override func viewWillDisappear(animated: Bool) {
        mainStore.unsubscribe(self)
        navigationController?.setNavigationBarHidden(false, animated: false)
        //navigationController?.hidesBarsOnSwipe = false
        print("LocationViewController Unsubscribed")
    }
    
    func newState(state: AppState) {
        print("New State!")
        let key = state.viewLocationKey
        let locations = state.locations
        for location in locations {
            if key == location.getKey() {
                self.location = location
                headerView.setLocation(self.location!)
            }
        }
        
        if state.viewUser != "" {
            pushUserProfile(state.viewUser)
        }
    }
    
    func downloadMedia() {
        self.photos = [StoryItem]()
        self.collectionView!.reloadData()
        FirebaseService.downloadStory(location!.getPostKeys(), completionHandler: { story in
            self.photos = story.reverse()
            self.collectionView!.reloadData()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = " "
        self.automaticallyAdjustsScrollViewInsets = false
        
        headerView = UINib(nibName: "LocationHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! LocationHeaderView
        headerView.delegate = self
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 40 + screenStatusBarHeight, left: 0, bottom: 200, right: 0)
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
        self.view.addSubview(collectionView!)
        
        controlBar = UINib(nibName: "UserProfileControlBarView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! UserProfileControlBar
        controlBar!.frame = CGRectMake(0,0, collectionView!.frame.width, 60)
        controlBar!.setControlBar()
        collectionView?.addSubview(controlBar!)
        
        statusBarBG = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: screenStatusBarHeight))
        statusBarBG!.backgroundColor = UIColor.blackColor()
        view.addSubview(statusBarBG!)
        statusBarBG!.hidden = true
        
    }
    
    func pushUserProfile(uid:String) {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("UserProfileViewController")
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func backTapped() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func messageTapped() {
        
    }
    
    func mediaDeleted() {
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
        
        if photos.count > 9 {
            return CGSize(width: screenWidth/4, height: screenWidth/4);
        }
        return CGSize(width: screenWidth/3, height: screenWidth/3);
    }

    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let progress = scrollView.parallaxHeader.progress
        headerView.setProgress(progress)
        print("progress: \(progress)")
        if progress < 0 {
            
            let scale = abs(progress)
            if let _ = controlBar {
                let shift = controlBar!.centerBlock.frame.height/5
                let scaleTransform = CGAffineTransformMakeScale(1 - scale/5, 1 - scale/5)
                let translateTransform = CGAffineTransformMakeTranslation(0, scale * shift)
                let transform = CGAffineTransformConcat(scaleTransform, translateTransform)
                controlBar!.leftBlock.transform = transform
                controlBar!.centerBlock.transform = transform
                controlBar!.rightBlock.transform = transform
            }
            
            if progress <= -1.0 {
                statusBarBG?.hidden = false
            } else {
                statusBarBG?.hidden = true
            }
        }
    }
    
    var selectedImageView : UIImageView?
    var selectedIndexPath: NSIndexPath?
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PhotoCell
        selectedImageView = cell.imageView
        selectedIndexPath = indexPath
        
        showInteractive()
    }
    
    var animator : ARNTransitionAnimator?
    
    func showInteractive() {
        let storyboard = UIStoryboard(name: "ModalViewController", bundle: nil)
        let controller = storyboard.instantiateViewControllerWithIdentifier("ModalViewController") as! ModalViewController
        controller.item = self.photos[self.selectedIndexPath!.item]
        controller.delegate = self
        let operationType: ARNTransitionAnimatorOperation = .Present
        let animator = ARNTransitionAnimator(operationType: operationType, fromVC: self, toVC: controller)
        
        animator.presentationBeforeHandler = { [weak self] containerView, transitionContext in
            containerView.addSubview(controller.view)
            
            
            controller.view.layoutIfNeeded()
            
            let sourceImageView = self!.createTransitionImageView()
            let destinationImageView = controller.createTransitionImageView()
            
            containerView.addSubview(sourceImageView)
            
            controller.presentationBeforeAction()
            
            controller.view.alpha = 0.0
            
            animator.presentationAnimationHandler = { containerView, percentComplete in
                sourceImageView.frame = destinationImageView.frame
                
                controller.view.alpha = 1.0
            }
            
            animator.presentationCompletionHandler = { containerView, completeTransition in
                sourceImageView.removeFromSuperview()
                self!.presentationCompletionAction(completeTransition)
                controller.presentationCompletionAction(completeTransition)
            }
        }
        
        animator.dismissalBeforeHandler = { [weak self] containerView, transitionContext in
            
            let fromVC = transitionContext.viewForKey(UITransitionContextFromViewKey)
            
            containerView.addSubview(fromVC!)
            containerView.bringSubviewToFront(controller.view)
            
            let sourceImageView = controller.createTransitionImageView()
            let destinationImageView = self!.createTransitionImageView()
            containerView.addSubview(sourceImageView)
            
            let sourceFrame = sourceImageView.frame;
            let destFrame = destinationImageView.frame;
            
            controller.dismissalBeforeAction()
            
            animator.dismissalCancelAnimationHandler = { (containerView: UIView) in
                sourceImageView.frame = sourceFrame
                controller.view.alpha = 1.0
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
                controller.view.alpha = 1.0 - (1.0 * percentComplete)
            }
            
            animator.dismissalCompletionHandler = { containerView, completeTransition in
                
                self!.dismissalCompletionAction(completeTransition)
                controller.dismissalCompletionAction(completeTransition)
                sourceImageView.removeFromSuperview()
            }
        }
        
        
        self.animator = animator
        self.animator!.interactiveType = .Dismiss
        controller.transitioningDelegate = self.animator
        self.presentViewController(controller, animated: true, completion: nil)
        
        
    }
    
    func Deanimate(){
        self.animator?.interactiveType = .None
    }
    
    func Reanimate(){
        self.animator?.interactiveType = .Present
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
        print("OFFSET: \(offset)")
        imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let imagePoint = CGPoint(x: attr!.center.x, y: attr!.center.y - offset)
        imageView.center = self.parentViewController!.view.convertPoint(imagePoint, fromView: self.view)
        
        
        
        return imageView
    }
    
    func presentationCompletionAction(completeTransition: Bool) {
        self.selectedImageView?.hidden = true
    }
    
    func dismissalCompletionAction(completeTransition: Bool) {
        self.selectedImageView?.hidden = false
    }
    
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
