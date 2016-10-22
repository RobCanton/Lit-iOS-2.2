//
//  UserProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-11.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift
import MXParallaxHeader
import ARNTransitionAnimator


class UserProfileViewController: UIViewController, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, HeaderProtocol, ControlBarProtocol, ZoomProtocol {

    var statusBarBG:UIView?

    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var photos = [StoryItem]()
    var collectionView:UICollectionView?
    var controlBar:UserProfileControlBar?
    var headerView:CreateProfileHeaderView!
    var user:User?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func backTapped() {

    }
    
    func messageTapped() {
        mainStore.dispatch(OpenConversation(uid: user!.getUserId()))
        tabBarController?.selectedIndex = 1
    }
    
    func friendBlockTapped() {
        let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewControllerWithIdentifier("UsersListViewController") as! UsersListViewController
        controller.title = "\(user!.getDisplayName())'s friends"
        controller.getUserFriends(user!.getUserId())
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func newState(state: AppState) {
        checkFriendStatus()
    }
    
    func mediaDeleted() {
        getKeys()
    }
    
    
    func checkFriendStatus() {
        guard let _ = user else {return}
        
        let friendStatus = FirebaseService.checkFriendStatus(user!.getUserId())
        headerView.setFriendStatus(friendStatus)

    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = " "
        self.automaticallyAdjustsScrollViewInsets = false

        headerView = UINib(nibName: "CreateProfileHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! CreateProfileHeaderView
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
        controlBar!.delegate = self
        collectionView?.addSubview(controlBar!)
        
        statusBarBG = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: screenStatusBarHeight))
        statusBarBG!.backgroundColor = UIColor.blackColor()
        view.addSubview(statusBarBG!)
        statusBarBG!.hidden = true
        
        if let _ = user {
            print("READY FOR USER")
            if let _ = headerView {
                print("tings")
                checkFriendStatus()
                headerView.imageView.loadImageUsingCacheWithURLString(user!.getLargeImageUrl(), completion: {result in})
                headerView.setUsername(user!.getDisplayName())
                controlBar?.setFriendsBlock(user!.getNumFriends())
                getKeys()
            }
        }
    }
    
    func getKeys() {
        let uid = user!.getUserId()
        var postKeys = [String]()
        let ref = FirebaseService.ref.child("users/uploads/\(uid)")
        ref.observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.exists() {
                for child in snapshot.children {
                    postKeys.append(child.key!!)
                }
                self.downloadStory(postKeys)
            }
            
        })
    }
    
    func downloadStory(postKeys:[String]) {
        controlBar?.setPostsBlock(postKeys.count)
        self.photos = [StoryItem]()
        collectionView?.reloadData()
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
        
        if let nav = navigationController as? ARNImageTransitionNavigationController {
            nav.doZoomTransition = true
        }
        showInteractive()
    }
    
    var animator : ARNTransitionAnimator?
    
    
    var isModeModal = false
    
    func Deanimate(){
        self.animator?.interactiveType = .None
    }
    
    func Reanimate(){
        self.animator?.interactiveType = .Present
    }
    

    var controller:ModalViewController!
    
    func showInteractive() {
        let storyboard = UIStoryboard(name: "ModalViewController", bundle: nil)
        controller = storyboard.instantiateViewControllerWithIdentifier("ModalViewController") as! ModalViewController
        controller.mode = .User
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
                //print(percentComplete)
                //self!.tabBarController?.setTabBarOffsetY(percentComplete)
                
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
                //print(percentComplete)
                //self!.tabBarController?.setTabBarOffsetY(-1 *  (1 - percentComplete))
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
            //self.tabBarController?.setTabBarVisible(false, animated: true)
            self.animator!.interactiveType = .Pop
            if let _nav = self.navigationController as? ARNImageTransitionNavigationController {
                _nav.interactiveAnimator = self.animator!
            }
            controller.animatorRef = self.animator!
            self.navigationController?.pushViewController(controller, animated: true)
        }
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
    }
    

}
