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

class ModalViewController: ARNModalImageTransitionViewController, ARNImageTransitionZoomable {
    
    var item:StoryItem?
    @IBOutlet weak var imageView : UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var authorImage: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var likeBtn: UIView!
    @IBOutlet weak var dislikeBtn: UIView!
    
    var delegate:ZoomProtocol!
    var mode:ModalMode = .Location
    var tap: UITapGestureRecognizer!
    var likeTap:UITapGestureRecognizer!
    
    var likeBtnTap: UITapGestureRecognizer!
    var dislikeBtnTap:UITapGestureRecognizer!
    
    
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
            self.dislikeBtn.layer.opacity = 1.0
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
        print("Liked photo!")
        if let _ = item {
            let ref = FirebaseService.ref.child("uploads/\(item!.getKey())/likes/\(mainStore.state.userState.uid)")
            ref.setValue(true)
        }
        setLike()
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
  
    }
    
    func dislike(gesture:UITapGestureRecognizer) {
        if let _ = item {
            let ref = FirebaseService.ref.child("uploads/\(item!.getKey())/likes/\(mainStore.state.userState.uid)")
            ref.setValue(false)
        }
        setDislike()
        dislikeBtn.transform = CGAffineTransformMakeScale(1.25, 1.25)
        UIView.animateWithDuration(0.3,
                                   delay: 0,
                                   usingSpringWithDamping: CGFloat(0.20),
                                   initialSpringVelocity: CGFloat(6.0),
                                   options: UIViewAnimationOptions.AllowUserInteraction,
                                   animations: {
                                    self.dislikeBtn.transform = CGAffineTransformIdentity
            },
                                   completion: { Void in()  }
        )

    }

    func setLike() {
        likeBtn.backgroundColor = accentColor
        let subview = likeBtn.subviews[0] as! UIButton
        subview.setImage(UIImage(named: "like_filled"), forState: .Normal)
        resetDislike()
        
    }

    func setDislike() {
        dislikeBtn.backgroundColor = errorColor
        let subview = dislikeBtn.subviews[0] as! UIButton
        subview.setImage(UIImage(named: "dislike_filled"), forState: .Normal)
        resetLike()
    }
    
    func resetLike() {
        likeBtn.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        let likeSubView = likeBtn.subviews[0] as! UIButton
        likeSubView.setImage(UIImage(named: "like"), forState: .Normal)
    }
    
    func resetDislike() {
        dislikeBtn.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        let dislikeSubView = dislikeBtn.subviews[0] as! UIButton
        dislikeSubView.setImage(UIImage(named: "dislike"), forState: .Normal)
    }
    

    var likesRef: FIRDatabaseReference?
    func listenForLikes() {
        likesRef = FirebaseService.ref.child("uploads/\(item!.getKey())/likes/\(mainStore.state.userState.uid)")
        likesRef!.observeEventType(.Value, withBlock: { snapshot in
            if snapshot.exists() {
                let liked = snapshot.value! as! Bool
                if liked {
                    self.setLike()
                } else {
                    self.setDislike()
                }
            } else {
                self.resetLike()
                self.resetDislike()
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
        dislikeBtnTap = UITapGestureRecognizer(target: self, action: #selector(dislike))
        
        likeTap.numberOfTapsRequired = 2
        
        likeBtn.layer.cornerRadius = likeBtn.frame.width/2
        dislikeBtn.layer.cornerRadius = dislikeBtn.frame.width/2
        
        likeBtn.addGestureRecognizer(likeBtnTap)
        dislikeBtn.addGestureRecognizer(dislikeBtnTap)
        
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
        self.dislikeBtn.layer.opacity = 0

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
