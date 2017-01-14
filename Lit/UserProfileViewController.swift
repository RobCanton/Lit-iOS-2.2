//
//  UserProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-11.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift

class MyUserProfileViewController: UserProfileViewController {
    
    override func viewDidLoad() {
        uid = mainStore.state.userState.uid
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        getKeys()
    }
}


class UserProfileViewController: UIViewController, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, EditProfileProtocol {

    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var posts = [StoryItem]()
    var collectionView:UICollectionView?
    var user:User?
    
    var uid:String!
    
    var followers = [String]()
    {
        didSet {
            getHeaderView()?.setFollowersCount(followers.count)
        }
    }
    var following = [String]()
        {
        didSet {
            getHeaderView()?.setFollowingCount(following.count)
        }
    }
    
    var postKeys = [String]()
        {
        didSet {

            getHeaderView()?.setPostsCount(postKeys.count)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemSideLength = (UIScreen.mainScreen().bounds.width - 4.0)/3.0
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "AvenirNext-DemiBold", size: 16.0)!,
             NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        
        collectionView = UICollectionView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height), collectionViewLayout: layout)
        
        let nib = UINib(nibName: "PhotoCell", bundle: nil)
        collectionView!.registerNib(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        let headerNib = UINib(nibName: "ProfileHeaderView", bundle: nil)
        
        self.collectionView?.registerNib(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView")
        
        collectionView!.contentInset = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.bounces = true
        collectionView!.pagingEnabled = false
        collectionView!.showsVerticalScrollIndicator = false
        collectionView!.backgroundColor = UIColor.blackColor()
        self.view.addSubview(collectionView!)
        
        
        getFullUser()
        
        
    }
    
    func getFullUser() {
        self.getHeaderView()?.fetched = false
        FirebaseService.getUser(uid, completionHandler: { _user in
            if _user != nil {
                FirebaseService.getUserFullProfile(_user!, completionHandler: { fullUser in
                    
                        self.getKeys()
                        self.user = fullUser
                        if self.user!.getUserId() == mainStore.state.userState.uid {
                            mainStore.dispatch(UpdateUser(user: self.user!))
                        }
                        
                        self.navigationItem.title = self.user!.getDisplayName()
                        
                        self.collectionView?.reloadData()
                        SocialService.listenToFollowers(self.user!.getUserId(), completionHandler: { followers in
                            self.followers = followers
                        })
                        
                        SocialService.listenToFollowing(self.user!.getUserId(), completionHandler: { following in
                            self.following = following
                        })
                })
            }
        })
    }
    
    var largeImageURL:String?
    var bio:String?
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.delegate = self
        
        if let tabBar = self.tabBarController as? PopUpTabBarController {
            tabBar.setTabBarVisible(true, animated: true)
        }
        
        if let nav = navigationController as? MasterNavigationController {
            
            nav.delegate = nav
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
        SocialService.stopListeningToFollowers(uid)
        SocialService.stopListeningToFollowing(uid)
        
    }
    
    func newState(state: AppState) {

        let status = checkFollowingStatus(uid)
        getHeaderView()?.setUserStatus(status)
    }

    
    
    func followersBlockTapped() {
        if followers.count == 0 { return }
        let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewControllerWithIdentifier("UsersListViewController") as! UsersListViewController
        controller.title = "Followers"
        controller.tempIds = followers
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func followingBlockTapped() {
        if following.count == 0 { return }
        let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewControllerWithIdentifier("UsersListViewController") as! UsersListViewController
        controller.title = "Following"
        controller.tempIds = following
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func messageBlockTapped() {
        
        let uid = mainStore.state.userState.uid
        let partner_uid = user!.getUserId()
        if uid == partner_uid { return }
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
    
    func editProfileTapped() {
        let controller = UIStoryboard(name: "EditProfileViewController", bundle: nil)
            .instantiateViewControllerWithIdentifier("EditProfileNavigationController") as! UINavigationController
        let c = controller.viewControllers[0] as! EditProfileViewController
        c.delegate = self
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    var presentConversation:Conversation?
    var partnerImage:UIImage?
    func presentConversation(conversation:Conversation) {
        FirebaseService.getUser(conversation.getPartnerId(), completionHandler: { user in
            if user != nil {
                
                loadImageUsingCacheWithURL(user!.getImageUrl(), completion: { image, fromCache in
                    self.presentConversation = conversation
                    self.partnerImage = image
                    self.performSegueWithIdentifier("toMessage", sender: self)
                })
            }
        })
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toMessage" {
            guard let conversation = presentConversation else { return }
            let controller = segue.destinationViewController as! ContainerViewController
            controller.hidesBottomBarWhenPushed = true
            controller.conversation = conversation
            controller.partnerImage = partnerImage
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let staticHeight:CGFloat = 275 + 50 + 8 + 56
        if user != nil {
            if let text = self.user!.bio {
                var size =  UILabel.size(withText: text, forWidth: collectionView.frame.size.width)
                let height2 = size.height + staticHeight + 8  // +8 for some bio padding
                size.height = height2
                return size
            }

        }
        let size =  CGSize(width: collectionView.frame.size.width, height: staticHeight) // +8 for some empty padding
        return size
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", forIndexPath: indexPath) as! ProfileHeaderView
            if user != nil {
                view.populateHeader(user!)
                
            }
            view.followersHandler = followersBlockTapped
            view.followingHandler = followingBlockTapped
            view.messageHandler = messageBlockTapped
            view.editProfileHandler = editProfileTapped
            view.setPostsCount(postKeys.count)
            view.setFollowersCount(followers.count)
            view.setFollowingCount(following.count)
            return view
        }

        return UICollectionReusableView()
    }

    func getKeys() {
        let ref = FirebaseService.ref.child("users/uploads/\(uid)")
        ref.observeSingleEventOfType(.Value, withBlock: { snapshot in
            var postKeys = [String]()
            if snapshot.exists() {
                for child in snapshot.children {
                    postKeys.append(child.key!!)
                }
            }
            print("KEYS: \(postKeys)")
            self.postKeys = postKeys
            self.downloadStory(postKeys)
        })
    }
    
    func downloadStory(postKeys:[String]) {
        if postKeys.count > 0 {
            FirebaseService.downloadStory(postKeys, completionHandler: { story in
                self.posts = story.reverse()
                self.collectionView!.reloadData()
            })
        } else {
            self.posts = [StoryItem]()
            self.collectionView!.reloadData()
        }
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
    var itemSideLength:CGFloat!
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength)
    }

    
    let transitionController: TransitionController = TransitionController()
    var selectedIndexPath: NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let _ = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PhotoCell

        self.selectedIndexPath = indexPath
        
        let galleryViewController: GalleryViewController = GalleryViewController()
        
        guard let tabBarController = self.tabBarController as? PopUpTabBarController else { return }
        
        galleryViewController.photos = self.posts
        galleryViewController.uid = uid
        galleryViewController.tabBarRef = tabBarController
        galleryViewController.transitionController = self.transitionController
        self.transitionController.userInfo = ["destinationIndexPath": indexPath, "initialIndexPath": indexPath]
        self.transitionController.rounded = false
        
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
    
    
    func getHeaderView() -> ProfileHeaderView? {
        if let header = collectionView?.supplementaryViewForElementKind(UICollectionElementKindSectionHeader, atIndexPath: NSIndexPath(forItem: 0, inSection: 0)) as? ProfileHeaderView {
            return header
        }
        return nil
    }
    
}

extension UserProfileViewController: View2ViewTransitionPresenting {
    
    func initialFrame(userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        
        guard let indexPath: NSIndexPath = userInfo?["initialIndexPath"] as? NSIndexPath, attributes: UICollectionViewLayoutAttributes = self.collectionView!.layoutAttributesForItemAtIndexPath(indexPath) else {
            return CGRect.zero
        }
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        let rect = CGRect(x: attributes.frame.origin.x, y: attributes.frame.origin.y + navHeight, width: attributes.frame.width, height: attributes.frame.height)
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


