//
//  UserProfileControlBar.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

protocol ControlBarProtocol {
    func friendBlockTapped()
    func messageBlockTapped()
}

class UserProfileControlBar: UIView {

    @IBOutlet weak var friendBtn: UIButton!
    @IBOutlet weak var messageBtn: UIButton!
    
    @IBOutlet weak var friendBlock: UIView!
    @IBOutlet weak var messageBlock: UIView!
    @IBOutlet weak var postsBlock: UIView!
    @IBOutlet weak var numFriendsBlock: UIView!
    
    @IBOutlet weak var numFriendsLabel: UILabel!
    @IBOutlet weak var postsLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var friendLabel: UILabel!
    
    var delegate:ControlBarProtocol?
    
    var friendTap:UITapGestureRecognizer!
    var numFriendsTap:UITapGestureRecognizer!
    var messageBlockTap:UITapGestureRecognizer!
    
    var status:FriendStatus = .NOT_FRIENDS
    var user:User!
    
    func setControlBar() {
        postsLabel.styleProfileBlockText(0, text: "Posts", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        numFriendsLabel.styleProfileBlockText(0, text: "Friends", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        
        friendTap = UITapGestureRecognizer(target: self, action: #selector(friendBlockTapped))
        friendBlock.userInteractionEnabled = true
        friendBlock.addGestureRecognizer(friendTap)
        
        messageBlockTap = UITapGestureRecognizer(target: self, action: #selector(messageBlockTapped))
        messageBlock.userInteractionEnabled = true
        messageBlock.addGestureRecognizer(messageBlockTap)
        
        numFriendsTap = UITapGestureRecognizer(target: self, action: #selector(numFriendsBlockTapped))
        numFriendsBlock.userInteractionEnabled = true
        numFriendsBlock.addGestureRecognizer(numFriendsTap)
    }
    
    func setFriendStatus(_status:FriendStatus) {
        self.status = _status
        switch status {
        case .IS_CURRENT_USER:
            friendLabel.styleProfileBlockText(0, text: "Edit Profile", color: UIColor.whiteColor(), color2: UIColor.clearColor())
            friendBtn.setImage(UIImage(named: "edit"), forState: .Normal)
            friendBtn.tintColor = UIColor.whiteColor()
            friendBtn.enabled = true
            messageLabel.styleProfileBlockText(0, text: "Settings", color: UIColor.whiteColor(), color2: UIColor.clearColor())
            messageBtn.setImage(UIImage(named: "settings"), forState: .Normal)
            break
        case .FRIENDS:
            friendLabel.styleProfileBlockText(0, text: "Friends", color: UIColor.whiteColor(), color2: UIColor.clearColor())
            friendBtn.setImage(UIImage(named: "friend_checked"), forState: .Normal)
            friendBtn.tintColor = UIColor.whiteColor()
            friendBtn.enabled = true
            messageLabel.styleProfileBlockText(0, text: "Message", color: UIColor.whiteColor(), color2: UIColor.clearColor())
            messageBtn.setImage(UIImage(named: "paperplane"), forState: .Normal)
            break
        case .PENDING_INCOMING:
            friendLabel.styleProfileBlockText(0, text: "Confirm", color: accentColor, color2: UIColor.clearColor())
            friendBtn.setImage(UIImage(named: "friend_add_filled"), forState: .Normal)
            friendBtn.tintColor = accentColor
            friendBtn.enabled = true
            messageLabel.styleProfileBlockText(0, text: "Message", color: UIColor.whiteColor(), color2: UIColor.clearColor())
            messageBtn.setImage(UIImage(named: "paperplane"), forState: .Normal)
            break
        case .PENDING_INCOMING_SEEN:
            friendLabel.styleProfileBlockText(0, text: "Confirm", color: accentColor, color2: UIColor.clearColor())
            friendBtn.setImage(UIImage(named: "friend_add_filled"), forState: .Normal)
            friendBtn.tintColor = accentColor
            friendBtn.enabled = true
            messageLabel.styleProfileBlockText(0, text: "Message", color: UIColor.whiteColor(), color2: UIColor.clearColor())
            messageBtn.setImage(UIImage(named: "paperplane"), forState: .Normal)
            break
        case .PENDING_OUTGOING:
            friendLabel.styleProfileBlockText(0, text: "Added", color: UIColor.lightGrayColor(), color2: UIColor.clearColor())
            friendBtn.setImage(UIImage(named: "friend_add_filled"), forState: .Normal)
            friendBtn.tintColor = UIColor.whiteColor()
            friendBtn.enabled = false
            messageLabel.styleProfileBlockText(0, text: "Message", color: UIColor.whiteColor(), color2: UIColor.clearColor())
            messageBtn.setImage(UIImage(named: "paperplane"), forState: .Normal)
            break
        case .NOT_FRIENDS:
            friendLabel.styleProfileBlockText(0, text: "Add Friend", color: UIColor.whiteColor(), color2: UIColor.clearColor())
            friendBtn.setImage(UIImage(named: "friend_add_filled"), forState: .Normal)
            friendBtn.tintColor = UIColor.whiteColor()
            friendBtn.enabled = true
            messageLabel.styleProfileBlockText(0, text: "Message", color: UIColor.whiteColor(), color2: UIColor.clearColor())
            messageBtn.setImage(UIImage(named: "paperplane"), forState: .Normal)
            break
        }
    }
    
    func populateUser(_user:User) {
        user = _user
    }
    
    func setPosts(numPosts:Int) {
        if numPosts != 1 {
            postsLabel.styleProfileBlockText(numPosts, text: "Posts", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        } else {
            postsLabel.styleProfileBlockText(numPosts, text: "Post", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        }
    }
    
    func setNumFriends(numFriends:Int) {
        if numFriends != 1 {
            numFriendsLabel.styleProfileBlockText(numFriends, text: "Friends", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        } else {
            numFriendsLabel.styleProfileBlockText(numFriends, text: "Friend", color: UIColor.whiteColor(), color2: UIColor.whiteColor())
        }
    }
    
    func friendBlockTapped(gesture:UITapGestureRecognizer) {
        friendBlock.removeGestureRecognizer(friendTap)
        switch status {
        case .FRIENDS:
            break
        case .NOT_FRIENDS:
            FirebaseService.sendFriendRequest(user.getUserId(), completionHandler: { success in})
            break
        case .PENDING_INCOMING:
            FirebaseService.acceptFriendRequest(user.getUserId())
            break
        case .PENDING_INCOMING_SEEN:
            FirebaseService.acceptFriendRequest(user.getUserId())
            break
        case .PENDING_OUTGOING:
            break
        default:
            break
        }
    }
    
    func numFriendsBlockTapped(gesture:UITapGestureRecognizer) {
        delegate?.friendBlockTapped()
    }
    
    func messageBlockTapped(gesture:UITapGestureRecognizer) {
        delegate?.messageBlockTapped()
    }
    
    func setBarScale(scale:CGFloat) {
        let shift = self.friendBlock.frame.height/5
        let scaleTransform = CGAffineTransformMakeScale(1 - scale/5, 1 - scale/5)
        let translateTransform = CGAffineTransformMakeTranslation(0, scale * shift)
        let transform = CGAffineTransformConcat(scaleTransform, translateTransform)
        self.friendBlock.transform = transform
        self.messageBlock.transform = transform
        self.postsBlock.transform = transform
        self.numFriendsBlock.transform = transform
    }
}
