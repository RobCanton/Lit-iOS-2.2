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

class ModalViewController: ARNModalImageTransitionViewController, ARNImageTransitionZoomable, UINavigationControllerDelegate {
    
    var ref:ARNTransitionAnimator?
    
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
    
    var delegate:ZoomProtocol?
    var mode:ModalMode = .Location
    var tap: UITapGestureRecognizer!
    var likeTap:UITapGestureRecognizer!
    
    var likeBtnTap: UITapGestureRecognizer!
    
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        listenForLikes()
        self.authorImage.layer.opacity = 0
        self.authorLabel.layer.opacity = 0
        self.timeLabel.layer.opacity = 0
        self.locationLabel.layer.opacity = 0
        
        UIView.animateWithDuration(0.75, animations: {
            self.authorImage.layer.opacity = 1.0
            self.authorLabel.layer.opacity = 1.0
            self.timeLabel.layer.opacity = 1.0
            self.locationLabel.layer.opacity = 1.0
            self.likeBtn.layer.opacity = 1.0
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    
    func profileTapped(gesture:UITapGestureRecognizer) {
        print("profile tapped")
        viewUser()
    }
    
    func viewUser() {
        if let _ = user {
            let uid = item!.getAuthorId()
            if let nav = navigationController as? ARNImageTransitionNavigationController {
                nav.doZoomTransition = false
            }
            let controller = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewControllerWithIdentifier("UserProfileViewController") as! UserProfileViewController
            controller.user = user!
            
            self.navigationController?.pushViewController(controller, animated: true)
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
                        FirebaseService.deletePost(self.item!, completionHandler: {})
                        self.delegate?.Deanimate()
                        self.navigationController?.popViewController(true, completion: {
                            self.delegate?.Reanimate()
                            self.delegate?.mediaDeleted()
                        })
                    }
                    
                })
                optionMenu.addAction(deleteAction)
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
                //self.likesLabel.text = getLikesString(self.item!.likes)
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
        
        tap = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        likeTap = UITapGestureRecognizer(target: self, action: #selector(like))
        
        likeBtnTap = UITapGestureRecognizer(target: self, action: #selector(like))
        likeTap.numberOfTapsRequired = 2
        
        likeBtn.layer.cornerRadius = likeBtn.frame.width/2
        likeBtn.addGestureRecognizer(likeBtnTap)
        
        imageView.userInteractionEnabled = true
        imageView.addGestureRecognizer(likeTap)
        let key = mainStore.state.viewLocationKey
        let locations = mainStore.state.locations

        for location in locations {
            if key == location.getKey() {
                //self.locationLabel.styleLocationTitle(location.getName().lowercaseString, size: 32)
                self.title = location.getName().lowercaseString
                
            }
        }
        
        let barButton = UIBarButtonItem(image: UIImage(named: "more"), style: .Plain, target: self, action: #selector(moreTap))
        barButton.imageInsets = UIEdgeInsetsMake(0, -10, 0, 10)
        self.navigationItem.rightBarButtonItem = barButton
        
        navigationItem.backBarButtonItem = nil
        navigationItem.backBarButtonItem = UIBarButtonItem()
        
        
        
        authorImage.layer.cornerRadius = authorImage.frame.width/2
        authorImage.clipsToBounds = true
        authorImage.layer.opacity = 0

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
    
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningForLikes()
        self.authorImage.layer.opacity = 0
        self.authorLabel.layer.opacity = 0
        self.timeLabel.layer.opacity = 0
        self.locationLabel.layer.opacity = 0
        self.likeBtn.layer.opacity = 0

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
        return true
        
    }
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
//        print("showed tings")
//        if viewController.isKindOfClass(ModalViewController) {
//            print("Showed modal")
//            if let nav = navigationController as? ARNImageTransitionNavigationController {
//                nav.doZoomTransition = true
//            }
//        }
    }


}
