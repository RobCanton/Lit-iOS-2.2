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


class UserProfileViewController: UIViewController, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, ControlBarProtocol, UINavigationControllerDelegate {

    var statusBarBG:UIView?

    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var photos = [StoryItem]()
    var collectionView:UICollectionView?
    var controlBar:UserProfileControlBar?
    var headerView:CreateProfileHeaderView!
    var user:User!
    
    var followButton = FollowButton()
    
    var status:FriendStatus = .NOT_FRIENDS
    
    var followers = [String]()
    {
        didSet {
            self.controlBar?.setFollowers(followers.count)
        }
    }
    var following = [String]()
        {
        didSet {
            self.controlBar?.setFollowing(following.count)
            
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        SocialService.listenToFollowers(user!.getUserId(), completionHandler: { followers in
            self.followers = followers
        })
        
        SocialService.listenToFollowing(user!.getUserId(), completionHandler: { following in
            self.following = following
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
        SocialService.stopListeningToFollowers(user!.getUserId())
        SocialService.stopListeningToFollowing(user!.getUserId())
    }
    
    func backTapped() {

    }
    
    func followersBlockTapped() {
        let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewControllerWithIdentifier("UsersListViewController") as! UsersListViewController
        controller.title = "Followers"
        controller.tempIds = followers
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func followingBlockTapped() {
        let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewControllerWithIdentifier("UsersListViewController") as! UsersListViewController
        controller.title = "Following"
        controller.tempIds = following
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func messageBlockTapped() {
        let uid = mainStore.state.userState.uid
        let partner_uid = user!.getUserId()
        if let conversation = checkForExistingConversation(partner_uid) {
            presentConversation(conversation)
        } else {
            let ref = FirebaseService.ref.child("conversations").childByAutoId()
            let conversationKey = ref.key
            ref.child(uid).setValue(["seen": [".sv":"timestamp"]], withCompletionBlock: { error, ref in

                let recipientUserRef = FirebaseService.ref.child("users/conversations/\(partner_uid)")
                recipientUserRef.child(uid).setValue(conversationKey)
                
                let currentUserRef = FirebaseService.ref.child("users/conversations/\(uid)")
                currentUserRef.child(partner_uid).setValue(conversationKey, withCompletionBlock: { error, ref in
                    let conversation = Conversation(key: conversationKey, partner_uid: partner_uid)
                    self.presentConversation(conversation)
                })
            })
        }

        
    }
    
    func presentConversation(conversation:Conversation) {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
        
        controller.conversation = conversation
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func newState(state: AppState) {
        updateFriendStatus()
        
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
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)

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
        
        if user.getUserId() == mainStore.state.userState.uid {
            controlBar?.messageBlock.userInteractionEnabled = false
            controlBar?.messageBlock.alpha = 0.5
        }
        
        statusBarBG = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: navHeight))
        statusBarBG!.backgroundColor = UIColor.blackColor()
        view.addSubview(statusBarBG!)
        statusBarBG!.hidden = true
        
        headerView.imageView.loadImageUsingCacheWithURLString(user!.getLargeImageUrl(), completion: {result in})
        headerView.populateUser(user!)
        //controlBar?.populateUser(user!)
        getKeys()
        
        followButton.setFollowButton()
        let barButton = UIBarButtonItem(customView: followButton)
        self.navigationItem.rightBarButtonItem = barButton
        
        controlBar?.setFollowing(followers.count)
        controlBar?.setFollowing(following.count)
        
    }
    
    
    func updateFriendStatus() {
        status =  checkFriendStatus(user.getUserId())
        //controlBar?.setFriendStatus(status)
        followButton.setUser(user)
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
        self.selectedIndexPath = indexPath
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        let presentedViewController: PresentedViewController = PresentedViewController()
        presentedViewController.tabBarRef = self.tabBarController! as! PopUpTabBarController
        //presentedViewController.stories = stories
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
}

extension UserProfileViewController: View2ViewTransitionPresenting {
    
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

