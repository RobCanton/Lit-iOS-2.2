//
//  ProfileHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class ProfileHeaderView: UICollectionReusableView {

    
    @IBOutlet weak var controlBarContainer: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var bioLabel: UILabel!
    
    @IBOutlet weak var followingLabel: UILabel!

    @IBOutlet weak var followersLabel: UILabel!
    
    @IBOutlet weak var postsLabel: UILabel!
    
    @IBOutlet weak var messageBtn: UIButton!
    
    @IBOutlet weak var followButton: UIButton!
    let subColor = UIColor(white: 0.4, alpha: 1.0)
    
    var user:User?
    var status:FollowingStatus?
    
    var messageHandler:(()->())?
    var followersHandler:(()->())?
    var followingHandler:(()->())?
    
    var followersTap: UITapGestureRecognizer!
    var followingTap: UITapGestureRecognizer!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        

    }
    
    func populateHeader(user:User){
        self.user = user
        loadImageUsingCacheWithURL(user.getLargeImageUrl(), completion: { image in
            self.profileImageView.image = image
        })
        postsLabel.styleProfileBlockText(13, text: "posts", color: subColor, color2: UIColor.whiteColor())
        followersLabel.styleProfileBlockText(158, text: "followers", color: subColor, color2: UIColor.whiteColor())
        followingLabel.styleProfileBlockText(87, text: "following", color: subColor, color2: UIColor.whiteColor())
        
//        followersLabel.center = CGPoint(x: (followingLabel.center.x - postsLabel.center.x) / 2 + postsLabel.center.x, y: postsLabel.center.y)
//        
        followButton.layer.cornerRadius = 2.0
        followButton.clipsToBounds = true
        
        messageBtn.layer.cornerRadius = 2.0
        messageBtn.clipsToBounds = true
   
        messageBtn.layer.borderWidth = 1.0
        messageBtn.layer.borderColor = UIColor.whiteColor().CGColor
        messageBtn.tintColor = UIColor.whiteColor()

        
        bioLabel.text = "MORE LIFE. MORE CHUNES.\nTop of 2017.\n\nOVOXO."
        
        setUserStatus(checkFollowingStatus(user.getUserId()))
        
        followersTap = UITapGestureRecognizer(target: self, action: #selector(handleFollowersTap))
        followingTap = UITapGestureRecognizer(target: self, action: #selector(handleFollowingTap))
        
        followersLabel.userInteractionEnabled = true
        followersLabel.addGestureRecognizer(followersTap)
        
        followingLabel.userInteractionEnabled = true
        followingLabel.addGestureRecognizer(followingTap)
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
            followButton.hidden = true
            messageBtn.hidden = true
            break
        case .Following:
            followButton.hidden = false
            followButton.backgroundColor = UIColor(white: 0.4, alpha: 1.0)
            followButton.setTitle("Following", forState: .Normal)
            messageBtn.hidden = false
            break
        case .None:
            followButton.hidden = false
            followButton.backgroundColor = accentColor
            followButton.setTitle("Follow", forState: .Normal)
            messageBtn.hidden = false
            break
            
        case .Requested:
            followButton.hidden = false
            followButton.backgroundColor = UIColor(white: 0.4, alpha: 1.0)
            followButton.setTitle("Requested", forState: .Normal)
            messageBtn.hidden = false
            break
        }
    }
    @IBAction func handleFollowTap(sender: AnyObject) {
        guard let user = self.user else { return }
        guard let status = self.status else { return }

        switch status {
        case .CurrentUser:
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
    
    @IBAction func handleMessageTap(sender: AnyObject) {
        
        messageHandler?()
    }
    
    func handleFollowersTap(sender:UITapGestureRecognizer) {
        followersHandler?()
    }
    
    func handleFollowingTap(sender:UITapGestureRecognizer) {
        followingHandler?()
    }
}
