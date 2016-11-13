//
//  UserProfileControlBar.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

protocol ControlBarProtocol {
    func followersBlockTapped()
    func followingBlockTapped()
    func messageBlockTapped()
}

class UserProfileControlBar: UIView {

    @IBOutlet weak var friendBtn: UIButton!
    @IBOutlet weak var messageBtn: UIButton!
    
    var delegate:ControlBarProtocol?
    
    var friendTap:UITapGestureRecognizer!
    var numFriendsTap:UITapGestureRecognizer!
    
    var followersBlockTap:UILongPressGestureRecognizer!
    var followingBlockTap:UILongPressGestureRecognizer!
    var messageBlockTap:UILongPressGestureRecognizer!
    
    
    @IBOutlet weak var postsBlock: UIView!
    @IBOutlet weak var postsLabel: UILabel!
    
    @IBOutlet weak var followersBlock: UIView!
    @IBOutlet weak var followersLabel: UILabel!
    
    @IBOutlet weak var followingBlock: UIView!
    @IBOutlet weak var followingLabel: UILabel!
    
    @IBOutlet weak var messageBlock: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var status:FriendStatus = .NOT_FRIENDS

    func setControlBar() {
        postsLabel.styleProfileBlockText(0, text: "Posts", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        followersLabel.styleProfileBlockText(0, text: "Followers", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        followingLabel.styleProfileBlockText(0, text: "Following", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        messageLabel.styleProfileBlockText(0, text: "Message", color: UIColor.whiteColor(), color2: UIColor.clearColor())

        followersBlockTap = UILongPressGestureRecognizer(target: self, action: #selector(followersBlockTapped))
        followersBlockTap.minimumPressDuration = 0
        followersBlock.userInteractionEnabled = true
        followersBlock.addGestureRecognizer(followersBlockTap)
        
        followingBlockTap = UILongPressGestureRecognizer(target: self, action: #selector(followingBlockTapped))
        followingBlockTap.minimumPressDuration = 0
        followingBlock.userInteractionEnabled = true
        followingBlock.addGestureRecognizer(followingBlockTap)
        
        messageBlockTap = UILongPressGestureRecognizer(target: self, action: #selector(messageBlockTapped))
        messageBlockTap.minimumPressDuration = 0
        messageBlock.userInteractionEnabled = true
        messageBlock.addGestureRecognizer(messageBlockTap)
        

    }
    
    func setPosts(numPosts:Int) {
        if numPosts != 1 {
            postsLabel.styleProfileBlockText(numPosts, text: "Posts", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        } else {
            postsLabel.styleProfileBlockText(numPosts, text: "Post", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        }
    }
    
    func setFollowers(numFollowers:Int) {
        if numFollowers != 1 {
            followersLabel.styleProfileBlockText(numFollowers, text: "Followers", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        } else {
            followersLabel.styleProfileBlockText(numFollowers, text: "Follower", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        }
    }
    
    func setFollowing(numFollowing:Int) {
        if numFollowing != 1 {
            followingLabel.styleProfileBlockText(numFollowing, text: "Following", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        } else {
            followingLabel.styleProfileBlockText(numFollowing, text: "Following", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        }
    }
    

    
    func followersBlockTapped(gesture:UITapGestureRecognizer) {
        
        // handle touch down and touch up events separately
        if gesture.state == .Began {
            UIView.animateWithDuration(0.15, animations: {
                self.followersBlock.alpha = 0.5
            })
            
        } else if gesture.state == .Ended { // optional for touch up event catching
            UIView.animateWithDuration(0.3, animations: {
                self.followersBlock.alpha = 1.0
            })
            delegate?.followersBlockTapped()
        }
    }
    
    func followingBlockTapped(gesture:UITapGestureRecognizer) {
        
        // handle touch down and touch up events separately
        if gesture.state == .Began {
            UIView.animateWithDuration(0.15, animations: {
                self.followingBlock.alpha = 0.5
            })
            
        } else if gesture.state == .Ended { // optional for touch up event catching
            UIView.animateWithDuration(0.3, animations: {
                self.followingBlock.alpha = 1.0
            })
            delegate?.followingBlockTapped()
        }
    }
    
    func messageBlockTapped(gesture:UITapGestureRecognizer) {
        
        // handle touch down and touch up events separately
        if gesture.state == .Began {
            UIView.animateWithDuration(0.15, animations: {
                self.messageBlock.alpha = 0.5
            })
            
        } else if gesture.state == .Ended { // optional for touch up event catching
            UIView.animateWithDuration(0.3, animations: {
                self.messageBlock.alpha = 1.0
            })
            delegate?.messageBlockTapped()
        }
    }
    
    func setBarScale(scale:CGFloat) {
//        let shift = self.friendBlock.frame.height/5
//        let scaleTransform = CGAffineTransformMakeScale(1 - scale/5, 1 - scale/5)
//        let translateTransform = CGAffineTransformMakeTranslation(0, scale * shift)
//        let transform = CGAffineTransformConcat(scaleTransform, translateTransform)
//        self.friendBlock.transform = transform
//        self.messageBlock.transform = transform
//        self.postsBlock.transform = transform
//        self.numFriendsBlock.transform = transform
    }
}
