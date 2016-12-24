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
    
    func populateHeader(user:User){

        self.user = user
        
        if let url = user.largeImageURL {
            loadImageUsingCacheWithURL(url, completion: { image in
                self.profileImageView.image = image
            })
        }
        if let bio = user.bio {
            bioLabel.text = bio
        }
        
        postsLabel.styleProfileBlockText(158, text: "posts", color: subColor, color2: UIColor.whiteColor())
        
        followersLabel.styleProfileBlockText(158, text: "followers", color: subColor, color2: UIColor.whiteColor())
        followingLabel.styleProfileBlockText(87, text: "following", color: subColor, color2: UIColor.whiteColor())
        messageLabel.styleProfileBlockText(0, text: "Message", color: UIColor.whiteColor(), color2: UIColor.clearColor())

        followButton.layer.cornerRadius = 2.0
        followButton.clipsToBounds = true
        followButton.layer.borderWidth = 1.0
        
        messageButton.layer.cornerRadius = 2.0
        messageButton.clipsToBounds = true
        
        if let name = user.getName() {
            nameLabel.text = name
        } else {
            nameLabel.text = user.getDisplayName()
        }
        
        
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
        
        let messageView = messageButton.superview!
        messageView.userInteractionEnabled = true
        messageView.addGestureRecognizer(messageTap)
 
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
            SocialService.followUser(user.getUserId())
            break
        case .Requested:
            break
        }
    }
    
    
    


    func handleFollowersTap(sender:UITapGestureRecognizer) {
        followersHandler?()
    }
    
    func handleFollowingTap(sender:UITapGestureRecognizer) {
        followingHandler?()
    }
    
    func handleMessageTap(sender:UITapGestureRecognizer) {
        messageHandler?()
    }
}
