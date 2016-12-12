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
import Firebase
import SwiftMessages


class CurrentUserProfileViewController: UIViewController, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, ControlBarProtocol, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
        collectionView!.pagingEnabled = false
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
    
    let transitionController: TransitionController = TransitionController()
    var selectedIndexPath: NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PhotoCell

        
        self.selectedIndexPath = indexPath
        
        let galleryViewController: GalleryViewController = GalleryViewController()
        
        guard let tabBarController = self.tabBarController as? PopUpTabBarController else { return }
        
        galleryViewController.photos = self.photos
        galleryViewController.tabBarRef = tabBarController
        galleryViewController.transitionController = self.transitionController
        self.transitionController.userInfo = ["destinationIndexPath": indexPath, "initialIndexPath": indexPath]
        
        // This example will push view controller if presenting view controller has navigation controller.
        // Otherwise, present another view controller
        if let navigationController = self.navigationController {
            
            // Set transitionController as a navigation controller delegate and push.
            navigationController.delegate = transitionController
            transitionController.push(viewController: galleryViewController, on: self, attached: galleryViewController)
            
        }
        
    }
}

extension CurrentUserProfileViewController: View2ViewTransitionPresenting {
    
    func initialFrame(userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        
        guard let indexPath: NSIndexPath = userInfo?["initialIndexPath"] as? NSIndexPath, attributes: UICollectionViewLayoutAttributes = self.collectionView!.layoutAttributesForItemAtIndexPath(indexPath) else {
            return CGRect.zero
        }
        return self.collectionView!.convertRect(attributes.frame, toView: self.collectionView!.superview)
    }
    
    func initialView(userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: NSIndexPath = userInfo!["initialIndexPath"] as! NSIndexPath
        let cell: UICollectionViewCell = self.collectionView!.cellForItemAtIndexPath(indexPath)!
        
        return cell.contentView
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

