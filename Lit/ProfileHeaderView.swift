//
//  ProfileHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class ProfileHeaderView: UICollectionReusableView {

    @IBOutlet weak var postsLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var controlBarContainer: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var errorLabel: UILabel!
    

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    
    
    
    @IBOutlet weak var dividerView: UIView!
    let subColor = UIColor(white: 0.5, alpha: 1.0)
    
    var user:User?
    var status:FollowingStatus?
    
    var messageHandler:(()->())?
    var followersHandler:(()->())?
    var followingHandler:(()->())?
    var editProfileHandler:(()->())?
    
    var followersTap: UITapGestureRecognizer!
    var followingTap: UITapGestureRecognizer!
    var messageTap: UITapGestureRecognizer!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        dividerView.layer.borderColor = UIColor(white: 0.15, alpha: 1.0).CGColor
        dividerView.layer.borderWidth = 0.5
    }
    
    var fetched = false
    
    func populateHeader(user:User){
        if fetched { return }
        fetched = true

        self.user = user
        
        if let url = user.largeImageURL {
            loadImageUsingCacheWithURL(url, completion: { image, fromCache in
                if image != nil {
                    self.errorLabel.hidden = true
                    if !fromCache {
                        self.profileImageView.alpha = 0.0
                        UIView.animateWithDuration(0.25, animations: {
                            self.profileImageView.alpha = 1.0
                        })
                    }
                    self.profileImageView.image = image
                } else {
                    self.errorLabel.hidden = false
                }

                
            })
        }
        if let bio = user.bio {
            bioLabel.text = bio
        }
        
        postsLabel.styleProfileBlockText(0, text: "posts", color: subColor, color2: UIColor.whiteColor())
        
        followersLabel.styleProfileBlockText(0, text: "followers", color: subColor, color2: UIColor.whiteColor())
        followingLabel.styleProfileBlockText(0, text: "following", color: subColor, color2: UIColor.whiteColor())
        messageLabel.styleProfileBlockText(0, text: "Message", color: UIColor.whiteColor(), color2: UIColor.clearColor())

        
        followButton.layer.cornerRadius = 2.0
        followButton.clipsToBounds = true
        followButton.layer.borderWidth = 1.0
        followButton.hidden = false

        messageButton.layer.cornerRadius = 2.0
        messageButton.clipsToBounds = true
        messageButton.hidden = false
        
        if let name = user.getName() {
            nameLabel.text = name
        } else {
            nameLabel.text = user.getDisplayName()
        }
        
        locationLabel.text = "@\(user.getDisplayName())"
        
        
        setUserStatus(checkFollowingStatus(user.getUserId()))
        
        followersTap = UITapGestureRecognizer(target: self, action: #selector(handleFollowersTap))
        followingTap = UITapGestureRecognizer(target: self, action: #selector(handleFollowingTap))
        messageTap = UITapGestureRecognizer(target: self, action: #selector(handleMessageTap))
        
        
        let followersView = followersLabel.superview!
        followersView.userInteractionEnabled = true
        followersView.addGestureRecognizer(followersTap)
        
        let followingView = followingLabel.superview!
        followingView.userInteractionEnabled = true
        followingView.addGestureRecognizer(followingTap)

        
        controlBarContainer.userInteractionEnabled = true
        let messageView = messageButton.superview!
        if user.uid == mainStore.state.userState.uid {
            messageView.alpha = 0.5
        } else {
            messageView.alpha = 1.0
            messageView.userInteractionEnabled = true
            messageView.addGestureRecognizer(messageTap)
        }
    }
    
    func setFullProfile(largeImageURL:String?, bio:String?) {
        
    }
    
    func setPostsCount(count:Int) {
        if count == 1 {
            postsLabel.styleProfileBlockText(count, text: "post", color: subColor, color2: UIColor.whiteColor())
        } else {
            postsLabel.styleProfileBlockText(count, text: "posts", color: subColor, color2: UIColor.whiteColor())
        }
    }
    
    func setFollowersCount(count:Int) {
        if count == 1 {
            followersLabel.styleProfileBlockText(count, text: "follower", color: subColor, color2: UIColor.whiteColor())
        } else {
            followersLabel.styleProfileBlockText(count, text: "followers", color: subColor, color2: UIColor.whiteColor())
        }
    }
    
    func setFollowingCount(count:Int) {
        followingLabel.styleProfileBlockText(count, text: "following", color: subColor, color2: UIColor.whiteColor())
    }
    
    
    func setUserStatus(status:FollowingStatus) {
        self.status = status
        print("UPDATE USER STATUS")
        switch status {
        case .CurrentUser:
            followButton.backgroundColor = UIColor.clearColor()
            followButton.layer.borderColor = UIColor.whiteColor().CGColor
            followButton.setTitle("Edit Profile", forState: .Normal)
            break
        case .None:
            followButton.backgroundColor = accentColor
            followButton.layer.borderColor = UIColor.clearColor().CGColor
            followButton.setTitle("Follow", forState: .Normal)
            break
        case .Requested:
            followButton.backgroundColor = UIColor.clearColor()
            followButton.layer.borderColor = UIColor.whiteColor().CGColor
            followButton.setTitle("Requested", forState: .Normal)
            break
        case .Following:
            followButton.backgroundColor = UIColor.clearColor()
            followButton.layer.borderColor = UIColor.whiteColor().CGColor
            followButton.setTitle("Following", forState: .Normal)
            break
        }
    }
    @IBAction func handleFollowTap(sender: AnyObject) {
        guard let user = self.user else { return }
        guard let status = self.status else { return }

        switch status {
        case .CurrentUser:
            editProfileHandler?()
            break
        case .Following:
            SocialService.unfollowUser(user.getUserId())
            break
        case .None:
            setUserStatus(.Requested)
            SocialService.followUser(user.getUserId())
            break
        case .Requested:
            break
        }
    }
    

    func handleFollowersTap(sender:UITapGestureRecognizer) {
        print("handleFollowersTap")
        followersHandler?()
    }
    
    func handleFollowingTap(sender:UITapGestureRecognizer) {
        print("handleFollowingTap")
        followingHandler?()
    }
    
    func handleMessageTap(sender:UITapGestureRecognizer) {
        print("handleMessageTap")
        messageHandler?()
    }
}
