//
//  UserProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-11.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift


class UserProfileViewController: UIViewController, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout {

    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var posts = [StoryItem]()
    var collectionView:UICollectionView?
    var user:User!
    
    var followers = [String]()
    {
        didSet {
            if let header = collectionView?.supplementaryViewForElementKind(UICollectionElementKindSectionHeader, atIndexPath: NSIndexPath(forItem: 0, inSection: 0)) as? ProfileHeaderView {
                header.setFollowersCount(followers.count)
            }
        }
    }
    var following = [String]()
        {
        didSet {
            if let header = collectionView?.supplementaryViewForElementKind(UICollectionElementKindSectionHeader, atIndexPath: NSIndexPath(forItem: 0, inSection: 0)) as? ProfileHeaderView {
                header.setFollowingCount(following.count)
            }
        }
    }
    
    var postKeys = [String]()
        {
        didSet {
            if let header = collectionView?.supplementaryViewForElementKind(UICollectionElementKindSectionHeader, atIndexPath: NSIndexPath(forItem: 0, inSection: 0)) as? ProfileHeaderView {
                header.setPostsCount(postKeys.count)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = user.getDisplayName()
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height), collectionViewLayout: layout)
        
        let nib = UINib(nibName: "PhotoCell", bundle: nil)
        collectionView!.registerNib(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        let headerNib = UINib(nibName: "ProfileHeaderView", bundle: nil)
        
        self.collectionView?.registerNib(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView")
        
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.bounces = true
        collectionView!.pagingEnabled = false
        collectionView!.showsVerticalScrollIndicator = false
        collectionView!.backgroundColor = UIColor.blackColor()
        self.view.addSubview(collectionView!)
        
        getKeys()
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
        if let nav = navigationController as? MasterNavigationController {
            nav.delegate = nav
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
        SocialService.stopListeningToFollowers(user!.getUserId())
        SocialService.stopListeningToFollowing(user!.getUserId())
    }
    
    func newState(state: AppState) {
        
        if let header = collectionView?.supplementaryViewForElementKind(UICollectionElementKindSectionHeader, atIndexPath: NSIndexPath(forItem: 0, inSection: 0)) as? ProfileHeaderView {
            let status = checkFollowingStatus(user.uid)
            header.setUserStatus(status)
        }
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
    
    var presentConversation:Conversation?
    func presentConversation(conversation:Conversation) {
        presentConversation = conversation
        self.performSegueWithIdentifier("toMessage", sender: self)
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toMessage" {
            guard let conversation = presentConversation else { return }
            let controller = segue.destinationViewController as! ContainerViewController
            controller.hidesBottomBarWhenPushed = true
            controller.conversation = conversation
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let text = "MORE LIFE. MORE CHUNES.\nTop of 2017.\n\nOVOXO."
        var size =  UILabel.size(withText: text, forWidth: collectionView.frame.size.width)
        var height2 = size.height + 275 + 8 + 40 + 8 + 4 + 12 + 52
        size.height = height2
        return size
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {

        switch kind {
        case UICollectionElementKindSectionHeader:

            let view = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", forIndexPath: indexPath) as! ProfileHeaderView
            view.populateHeader(user)
            view.followersHandler = followersBlockTapped
            view.followingHandler = followingBlockTapped
            view.messageHandler = messageBlockTapped
            view.setPostsCount(postKeys.count)
            view.setFollowersCount(followers.count)
            view.setFollowingCount(following.count)
            return view
            break
        default:
            return UICollectionReusableView()
            break
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
                self.postKeys = postKeys
                self.downloadStory(postKeys)
            }
        })
    }
    
    func downloadStory(postKeys:[String]) {
        self.posts = [StoryItem]()
        collectionView?.reloadData()
        FirebaseService.downloadStory(postKeys, completionHandler: { story in
            self.posts = story.reverse()
            self.collectionView!.reloadData()
        })
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PhotoCell
        cell.setPhoto(posts[indexPath.item])
        return cell
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return getItemSize()
    }
    
    func getItemSize() -> CGSize {
        
        return CGSize(width: screenWidth/3, height: screenWidth/3);
    }
    

    func scrollViewDidScroll(scrollView: UIScrollView) {

    }
    
    let transitionController: TransitionController = TransitionController()
    var selectedIndexPath: NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PhotoCell

        self.selectedIndexPath = indexPath
        
        let galleryViewController: GalleryViewController = GalleryViewController()
        
        guard let tabBarController = self.tabBarController as? PopUpTabBarController else { return }
        
        galleryViewController.photos = self.posts
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
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

extension UserProfileViewController: View2ViewTransitionPresenting {
    
    func initialFrame(userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        
        guard let indexPath: NSIndexPath = userInfo?["initialIndexPath"] as? NSIndexPath, attributes: UICollectionViewLayoutAttributes = self.collectionView!.layoutAttributesForItemAtIndexPath(indexPath) else {
            return CGRect.zero
        }
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        var rect = CGRect(x: attributes.frame.origin.x, y: attributes.frame.origin.y + navHeight, width: attributes.frame.width, height: attributes.frame.height)
        return self.collectionView!.convertRect(rect, toView: self.collectionView!.superview)
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


