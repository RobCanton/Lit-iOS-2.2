//
//  CurrentUserProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-25.
//  Copyright © 2016 Robert Canton. All rights reserved.
//
import UIKit
import ReSwift
import MXParallaxHeader
import ARNTransitionAnimator
import Firebase
import SwiftMessages


class CurrentUserProfileViewController: UIViewController, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, ControlBarProtocol, ZoomProtocol, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var statusBarBG:UIView?
    
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var photos = [StoryItem]()
    var collectionView:UICollectionView?
    var controlBar:UserProfileControlBar?
    var headerView:CreateProfileHeaderView!
    
    var largeProfileImageView:UIImageView = UIImageView()
    var smallProfileImageView:UIImageView = UIImageView()
    let imagePicker = UIImagePickerController()
    
    var user:User? = mainStore.state.userState.user
    
    var headerTap:UITapGestureRecognizer!
    var profilePhotoMessageView:ProfilePictureMessageView?
    var config: SwiftMessages.Config?
    var profilePhotoMessageWrapper = SwiftMessages()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    
    func followersBlockTapped() {
        
    }
    
    func followingBlockTapped() {
        
    }
    
    func messageBlockTapped() {
        self.performSegueWithIdentifier("toSettings", sender: self)
    }
    
    func messageTapped() {
        mainStore.dispatch(OpenConversation(uid: user!.getUserId()))
        tabBarController?.selectedIndex = 1
    }
    
    func friendBlockTapped() {
        let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewControllerWithIdentifier("UsersListViewController") as! UsersListViewController
        controller.title = "\(user!.getDisplayName())'s friends"
        controller.setTypeToFriends(user!.getUserId())
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func newState(state: AppState) {
        updateFriendStatus()
        let followers = mainStore.state.socialState.followers
        let following = mainStore.state.socialState.following
        controlBar?.setFollowers(followers.count)
        controlBar?.setFollowing(following.count)
    }
    
    func mediaDeleted() {
        getKeys()
    }
    
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = " "
        self.automaticallyAdjustsScrollViewInsets = false

        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Book", size: 20.0)!]
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barStyle = .Black
        self.navigationController?.navigationBar.translucent = true
        
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        
        headerView = UINib(nibName: "CreateProfileHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! CreateProfileHeaderView
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: navHeight, left: 0, bottom: 200, right: 0)
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
        controlBar!.frame = CGRectMake(0,0, collectionView!.frame.width, navHeight)
        controlBar!.setControlBar()
        controlBar!.delegate = self
        collectionView?.addSubview(controlBar!)
        
        statusBarBG = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: screenStatusBarHeight))
        statusBarBG!.backgroundColor = UIColor.blackColor()
        view.addSubview(statusBarBG!)
        statusBarBG!.hidden = true
        
        if let _ = user {
            if let _ = headerView {
                headerView.imageView.loadImageUsingCacheWithURLString(user!.getLargeImageUrl(), completion: {result in})
                headerView.populateUser(user!)

                getKeys()
            }
            
            
        }
        
        headerTap = UITapGestureRecognizer(target: self, action: #selector(showProfilePhotoMessagesView))
        headerView.imageView.addGestureRecognizer(headerTap)
        headerView.imageView.userInteractionEnabled = true
        imagePicker.delegate = self
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            let largeImage = resizeImage(pickedImage, newWidth: 720)
            let smallImage = resizeImage(pickedImage, newWidth: 150)
            uploadProfileImages(largeImage, smallImage: smallImage)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func setFacebookProfilePicture() {
        FacebookGraph.getProfilePicture({ imageURL in
            if imageURL != nil {
                self.largeProfileImageView.loadImageUsingCacheWithURLString(imageURL!, completion: { result in
                    let largeImage = self.largeProfileImageView.image!
                    let smallImage = resizeImage(self.largeProfileImageView.image!, newWidth: 150)
                    self.uploadProfileImages(largeImage, smallImage: smallImage)
                })

            }
        })
    }
    
    func uploadProfileImages(largeImage:UIImage, smallImage:UIImage) {
        UserService.uploadProfilePicture(largeImage, smallImage: smallImage, completionHandler: { success, largeImageURL, smallImageURL in
            if success {
                UserService.updateProfilePictureURL(largeImageURL!, smallURL: smallImageURL!, completionHandler: {
                    mainStore.dispatch(UpdateProfileImageURL(largeImageURL: largeImageURL!, smallImageURL: smallImageURL!))
                    self.headerView.imageView.loadImageUsingCacheWithURLString(largeImageURL!, completion: {result in})
                })
            }
        })
    }
    
    func showProfilePhotoMessagesView() {
        profilePhotoMessageView = try! SwiftMessages.viewFromNib() as? ProfilePictureMessageView
        profilePhotoMessageView!.configureDropShadow()
        
        profilePhotoMessageView!.facebookHandler = {
            self.profilePhotoMessageWrapper.hide()
            self.setFacebookProfilePicture()
        }
        
        profilePhotoMessageView!.libraryHandler = {
            self.profilePhotoMessageWrapper.hide()
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .PhotoLibrary
            self.presentViewController(self.imagePicker, animated: true, completion: nil)
        }
        
        profilePhotoMessageView!.cancelHandler = {
            self.profilePhotoMessageWrapper.hide()
        }
        
        config = SwiftMessages.Config()
        config!.presentationContext = .Window(windowLevel: UIWindowLevelStatusBar)
        config!.duration = .Forever
        config!.presentationStyle = .Bottom
        config!.dimMode = .Gray(interactive: true)
        profilePhotoMessageWrapper.show(config: config!, view: profilePhotoMessageView!)
    }
    
    func updateFriendStatus() {
        
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
        controlBar?.setPosts(postKeys.count)
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
        if progress < 0 {
            
            let scale = abs(progress)
            if let _ = controlBar {
                controlBar!.setBarScale(scale)
            }
            
            if scale > 0.80 {
                let prop = ((scale - 0.80) / 0.20) * 1.15
                controlBar?.alpha = 1 - prop
            } else {
                controlBar?.alpha = 1
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
    
    
    func createTransitionImageView() -> UIImageView {
        
        let imageView = UIImageView()
        imageView.loadImageUsingCacheWithURLString(photos[selectedIndexPath!.item].getDownloadUrl().absoluteString, completion: { result in})
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
    
//    @IBAction func settingsTapped(sender: AnyObject) {
//        
//        // 1
//        let optionMenu = UIAlertController(title: nil, message: "Options", preferredStyle: .ActionSheet)
//        
//        // 2
//        let logoutAction = UIAlertAction(title: "Logout", style: .Destructive, handler: {
//            (alert: UIAlertAction!) -> Void in
//            let loginManager = FBSDKLoginManager()
//            loginManager.logOut()
//            try! FIRAuth.auth()!.signOut()
//            mainStore.dispatch(UserIsUnauthenticated())
//            
//            
//        })
//        
//        //
//        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
//            (alert: UIAlertAction!) -> Void in
//        })
//        
//        
//        // 4
//        optionMenu.addAction(logoutAction)
//        optionMenu.addAction(cancelAction)
//        
//        // 5
//        self.presentViewController(optionMenu, animated: true, completion: nil)
//    }
    
}
