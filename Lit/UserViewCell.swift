
//
//  UserViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class UserViewCell: UITableViewCell {

    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var imageContainer: UIView!
    
    @IBOutlet weak var followButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        contentImageView.layer.cornerRadius = contentImageView.frame.width/2
        contentImageView.clipsToBounds = true
        
        followButton.layer.cornerRadius = 3.0
        followButton.clipsToBounds = true
        followButton.layer.borderWidth = 1.0
        followButton.hidden = false
        
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    var user:User?
    
    var status:FollowingStatus?
    
    func setupUser(uid:String) {
        contentImageView.image = nil
        
        FirebaseService.getUser(uid, completionHandler: { user in
            if user != nil {
                self.user = user!
                self.contentImageView.loadImageUsingCacheWithURLString(user!.getImageUrl(), completion: { result in })
                self.usernameLabel.text = user!.getDisplayName()
                
            }
        })
        
        setUserStatus(checkFollowingStatus(uid))
    }
    
    func setUserStatus(status:FollowingStatus) {
        if self.status == status { return }
        self.status = status
        
        switch status {
        case .CurrentUser:
            followButton.hidden = true
            break
        case .None:
            followButton.hidden = false
            followButton.backgroundColor = accentColor
            followButton.layer.borderColor = UIColor.clearColor().CGColor
            followButton.setTitle("Follow", forState: .Normal)
            break
        case .Requested:
            followButton.hidden = false
            followButton.backgroundColor = UIColor.clearColor()
            followButton.layer.borderColor = UIColor.whiteColor().CGColor
            followButton.setTitle("Requested", forState: .Normal)
            break
        case .Following:
            followButton.hidden = false
            followButton.backgroundColor = UIColor.clearColor()
            followButton.layer.borderColor = UIColor.whiteColor().CGColor
            followButton.setTitle("Following", forState: .Normal)
            break
        }
    }
    
    var unfollowHandler:((user:User)->())?
    
    @IBAction func handleFollowTap(sender: AnyObject) {
        guard let user = self.user else { return }
        guard let status = self.status else { return }
        
        switch status {
        case .CurrentUser:
            break
        case .Following:
            unfollowHandler?(user: user)
            break
        case .None:
            setUserStatus(.Requested)
            SocialService.followUser(user.getUserId())
            break
        case .Requested:
            break
        }
    }
    
}
