//
//  ModalViewController.swift
//  ARNZoomImageTransition
//
//  Created by xxxAIRINxxx on 2015/08/08.
//  Copyright (c) 2015 xxxAIRINxxx. All rights reserved.
//

import UIKit
import Firebase

enum ModalMode {
    case Location, User
}

protocol ZoomProtocol {
    func Deanimate()
    func Reanimate()
}

enum LikeStatus {
    case None, Liked
}

class ModalViewController: ARNModalImageTransitionViewController, ARNImageTransitionZoomable {
    
    var item:StoryItem?
    @IBOutlet weak var imageView : UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var authorImage: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var likeBtn: UIView!
    
    var delegate:ZoomProtocol!
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
    
    deinit {

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


    
    func profileTapped(gesture:UITapGestureRecognizer) {
        print("profile tapped")
        let uid = item!.getAuthorId()

        delegate.Deanimate()
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: {
            
            self.delegate.Reanimate()
            if self.mode == .Location {
               mainStore.dispatch(ViewUser(uid: uid))
            }
        })
    }
    
    
    func like(gesture:UITapGestureRecognizer) {
        let ref = FirebaseService.ref.child("uploads/\(item!.getKey())/likes/\(mainStore.state.userState.uid)")
        if likeStatus == .None {
            if let _ = item {
                ref.setValue(true)
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
                ref.removeValue()
                likeStatus = .None
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
    func listenForLikes() {
        likesRef = FirebaseService.ref.child("uploads/\(item!.getKey())/likes/\(mainStore.state.userState.uid)")
        likesRef!.observeEventType(.Value, withBlock: { snapshot in
            if snapshot.exists() {
                let liked = snapshot.value! as! Bool
                if liked {
                    self.likeStatus = .Liked
                }
            } else {
                self.likeStatus = .None
            }
        })
    }
    
    func stopListeningForLikes() {
        likesRef?.removeAllObservers()
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
                self.locationLabel.styleLocationTitle(location.getName().lowercaseString, size: 32)
            }
        }
        
        authorImage.layer.cornerRadius = authorImage.frame.width/2
        authorImage.clipsToBounds = true
        authorImage.layer.opacity = 0

        authorImage.userInteractionEnabled = true
        authorImage.addGestureRecognizer(tap)
        
        authorLabel.layer.opacity = 0
        timeLabel.layer.opacity = 0
        locationLabel.layer.opacity = 0
        
        FirebaseService.getUser(item!.getAuthorId(), completionHandler: { _user in
            if let user = _user {
                self.authorLabel.text = user.getDisplayName()
                self.timeLabel.text = self.item!.getDateCreated()!.timeStringSinceNow()
                self.authorImage.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in
                })
                
            }
            
        })
        
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
}
