//
//  ModalViewController.swift
//  ARNZoomImageTransition
//
//  Created by xxxAIRINxxx on 2015/08/08.
//  Copyright (c) 2015 xxxAIRINxxx. All rights reserved.
//

import UIKit
import Firebase
import ARNTransitionAnimator

enum ModalMode {
    case Location, User
}

protocol ZoomProtocol {
    func Deanimate()
    func Reanimate()
    func mediaDeleted()
}

enum LikeStatus {
    case None, Liked
}

class ModalViewController: ARNModalImageTransitionViewController, ARNImageTransitionZoomable, UINavigationBarDelegate {
    
    var animatorRef:ARNTransitionAnimator?
    
    var dotings = true
    var item:StoryItem?
    @IBOutlet weak var imageView : UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var authorImage: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var likeBtn: UIView!
    //@IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var likesLabel: UIButton!
    @IBOutlet weak var gradientView: UIView!
    
    var delegate:ZoomProtocol?
    var mode:ModalMode = .Location
    var tap: UITapGestureRecognizer!
    var likeTap:UITapGestureRecognizer!
    
    var likeBtnTap: UITapGestureRecognizer!
    
    @IBAction func likesBtnTapped(sender: AnyObject) {
        if let nav = navigationController as? ARNImageTransitionNavigationController {
            nav.doZoomTransition = false
        }
        let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewControllerWithIdentifier("UsersListViewController") as! UsersListViewController
        controller.title = "likes"
        controller.setTypeToLikes(item!.getKey())
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    
    var likeStatus = LikeStatus.None
        {
        didSet {
            switch likeStatus{
            case .Liked:
                setLike()
                break
            case .None:
                resetLike()
                break
                
            }
        }
    }
    
    var user:User?
    {
        didSet {
            self.authorLabel.text = user!.getDisplayName()
            self.timeLabel.text = self.item!.getDateCreated()!.timeStringSinceNow()
            self.authorImage.loadImageUsingCacheWithURLString(user!.getImageUrl(), completion: { result in
            })
        }
    }
    
    func navigationBar(navigationBar: UINavigationBar, shouldPopItem item: UINavigationItem) -> Bool {
        delegate?.Deanimate()
        return true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: navigationController, action: nil)
        navigationItem.leftBarButtonItem = backButton
        listenForLikes()
        self.authorImage.alpha = 0
        self.authorLabel.alpha = 0
        self.timeLabel.alpha = 0
        self.locationLabel.alpha = 0
        self.likesLabel.alpha = 0.0
        self.likeBtn.alpha = 0.0
        self.gradientView.alpha = 0.0
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        if let tabBar = self.tabBarController as? PopUpTabBarController {
            tabBar.setTabBarVisible(false, animated: true)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animateWithDuration(0.2, animations: {
            self.authorImage.alpha = 1.0
            self.authorLabel.alpha = 1.0
            self.timeLabel.alpha = 1.0
            self.locationLabel.alpha = 1.0
            self.likeBtn.alpha = 1.0
            self.likesLabel.alpha = 1.0
            self.gradientView.alpha = 1.0
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningForLikes()
        self.authorImage.alpha = 0
        self.authorLabel.alpha = 0
        self.timeLabel.alpha = 0
        self.locationLabel.alpha = 0
        self.likeBtn.alpha = 0
        self.likesLabel.alpha = 0
        self.gradientView.alpha = 0.0
//        if let tabBar = self.tabBarController as? PopUpTabBarController {
//            tabBar.setTabBarVisible(true, animated: true)
//        }
    }
    
    func profileTapped(gesture:UITapGestureRecognizer) {
        print("profile tapped")
        viewUser()
    }
    
    func viewUser() {
        if mode == .Location {
            if let _ = user {
                if let nav = navigationController as? ARNImageTransitionNavigationController {
                    nav.doZoomTransition = false
                }
                let controller = UIStoryboard(name: "Main", bundle: nil)
                    .instantiateViewControllerWithIdentifier("UserProfileViewController") as! UserProfileViewController
                controller.user = user!
                
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    func moreTap() {
        let optionMenu = UIAlertController(title: nil, message: "Options", preferredStyle: .ActionSheet)
        if let _ = item {
            if item?.getAuthorId() == mainStore.state.userState.uid {
                
                /* Show post edit options */
                let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: {
                    (alert: UIAlertAction!) -> Void in
                    if let _ = self.item {
                        
                        FirebaseService.deletePost(self.item!, completionHandler: {
                            self.delegate?.mediaDeleted()
                            self.navigationController?.popViewControllerAnimated(false)
                            
                        })
                        if let tab =  self.tabBarController as? PopUpTabBarController {
                            tab.setTabBarVisible(true, animated: true)
                        }
                    }
                    
                })
                
                let testAction = UIAlertAction(title: "Test", style: .Default, handler: { (alert: UIAlertAction!) -> Void in
                    self.delegate?.Deanimate()
                    self.navigationController?.popViewControllerAnimated(false)
                })
                optionMenu.addAction(deleteAction)
                optionMenu.addAction(testAction)
            } else {
                /* show post report options */
                
                let viewUserAction = UIAlertAction(title: "View Profile", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    self.viewUser()
                })
                
                let reportAction = UIAlertAction(title: "Report", style: .Destructive, handler: {
                    (alert: UIAlertAction!) -> Void in
                })
                
                optionMenu.addAction(viewUserAction)
                optionMenu.addAction(reportAction)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            
            optionMenu.addAction(cancelAction)
            self.presentViewController(optionMenu, animated: true, completion: nil)
            
        }
    }
    
    func like(gesture:UITapGestureRecognizer) {
        let ref = FirebaseService.ref.child("uploads/\(item!.getKey())")
        if likeStatus == .None {
            if let _ = item {
                ref.child("/likes/\(mainStore.state.userState.uid)").setValue(true)
                
                ref.child("meta/likes").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                    if var numLikes = currentData.value as? Int {
                        
                        numLikes += 1
                        currentData.value = numLikes
                        
                        return FIRTransactionResult.successWithValue(currentData)
                    }
                    return FIRTransactionResult.successWithValue(currentData)
                }) { (error, committed, snapshot) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                }
            }
            likeStatus = .Liked
            likeBtn.transform = CGAffineTransformMakeScale(1.25, 1.25)
            UIView.animateWithDuration(0.3,
                                       delay: 0,
                                       usingSpringWithDamping: CGFloat(0.20),
                                       initialSpringVelocity: CGFloat(6.0),
                                       options: UIViewAnimationOptions.AllowUserInteraction,
                                       animations: {
                                        self.likeBtn.transform = CGAffineTransformIdentity
                },
                                       completion: { Void in()  }
            )
        } else {
            if let _ = item {
                ref.child("/likes/\(mainStore.state.userState.uid)").removeValue()
                likeStatus = .None
                
                ref.child("meta/likes").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                    if var numLikes = currentData.value as? Int {
                        
                        numLikes -= 1
                        currentData.value = numLikes
                        
                        return FIRTransactionResult.successWithValue(currentData)
                    }
                    return FIRTransactionResult.successWithValue(currentData)
                }) { (error, committed, snapshot) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func setLike() {
        likeBtn.backgroundColor = accentColor
        let subview = likeBtn.subviews[0] as! UIButton
        subview.setImage(UIImage(named: "like_filled"), forState: .Normal)
        
    }
    
    func resetLike() {
        likeBtn.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        let likeSubView = likeBtn.subviews[0] as! UIButton
        likeSubView.setImage(UIImage(named: "like"), forState: .Normal)
    }
    
    var likesRef: FIRDatabaseReference?
    var userLikedRef: FIRDatabaseReference?
    func listenForLikes() {
        userLikedRef = FirebaseService.ref.child("uploads/\(item!.getKey())/likes/\(mainStore.state.userState.uid)")
        userLikedRef!.observeEventType(.Value, withBlock: { snapshot in
            if snapshot.exists() {
                let liked = snapshot.value! as! Bool
                if liked {
                    self.likeStatus = .Liked
                }
            } else {
                self.likeStatus = .None
            }
        })
        
        likesRef = FirebaseService.ref.child("uploads/\(item!.getKey())/meta/likes")
        likesRef?.observeEventType(.Value, withBlock: { snapshot in
            if snapshot.exists() {
                let likes = snapshot.value! as! Int
                self.item!.likes = likes
                self.likesLabel.setTitle(getLikesString(self.item!.likes), forState: .Normal)
            }
        })
    }
    
    func stopListeningForLikes() {
        likesRef?.removeAllObservers()
        userLikedRef?.removeAllObservers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = " "
        
        tap = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        likeTap = UITapGestureRecognizer(target: self, action: #selector(like))
        
        likeBtnTap = UITapGestureRecognizer(target: self, action: #selector(like))
        likeTap.numberOfTapsRequired = 2
        
        likeBtn.layer.cornerRadius = likeBtn.frame.width/2
        likeBtn.addGestureRecognizer(likeBtnTap)
        
        
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [UIColor.clearColor().CGColor, UIColor(white: 0.0, alpha: 0.6).CGColor]
        gradient.locations = [0.0 , 1.0]
        
        gradient.frame = gradientView.bounds
        gradientView.layer.insertSublayer(gradient, atIndex: 0)
        
        imageView.userInteractionEnabled = true
        imageView.addGestureRecognizer(likeTap)
        
        let barButton = UIBarButtonItem(image: UIImage(named: "more"), style: .Plain, target: self, action: #selector(moreTap))
        barButton.imageInsets = UIEdgeInsetsMake(0, -10, 0, 10)
        self.navigationItem.rightBarButtonItem = barButton
        
        authorImage.layer.cornerRadius = authorImage.frame.width/2
        authorImage.clipsToBounds = true
        authorImage.layer.opacity = 0
        authorImage.layer.borderColor = UIColor.whiteColor().CGColor
        authorImage.layer.borderWidth = 1.0

        authorImage.userInteractionEnabled = true
        authorImage.addGestureRecognizer(tap)
        
        
        authorLabel.layer.opacity = 0
        timeLabel.layer.opacity = 0
        locationLabel.layer.opacity = 0
        
        self.likesLabel.setTitle(getLikesString(self.item!.likes), forState: .Normal)
        
        FirebaseService.getUser(item!.getAuthorId(), completionHandler: { _user in
            if let _ = _user {
                self.user = _user
            }
            
        })
        
        if let _ = item {
            self.imageView.loadImageUsingCacheWithURLString(item!.getDownloadUrl()!.absoluteString, completion: { result in })
        }
    }
    
    // MARK: - ARNImageTransitionZoomable
    
    func createTransitionImageView() -> UIImageView {
        if let _ = item {
            self.imageView.loadImageUsingCacheWithURLString(item!.getDownloadUrl()!.absoluteString, completion: { result in })
        }
        let imageView = UIImageView(image: self.imageView.image)
        imageView.contentMode = self.imageView.contentMode
        imageView.clipsToBounds = true
        imageView.userInteractionEnabled = false
        imageView.frame = self.imageView!.frame
        return imageView
    }
    
    
    func presentationBeforeAction() {
        self.imageView.hidden = true
    }
    
    func presentationCompletionAction(completeTransition: Bool) {
        self.imageView.hidden = false
    }
    
    func dismissalBeforeAction() {
        self.imageView.hidden = true
    }
    
    func dismissalCompletionAction(completeTransition: Bool) {
        if !completeTransition {
            self.imageView.hidden = false
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }

}
