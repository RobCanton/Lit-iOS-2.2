//
//  UserTableViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {


    @IBOutlet weak var friendButton: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    var status:FollowingStatus = FollowingStatus.None
    
    var user:User? {
        didSet{
            profileImageView.image = nil
            profileImageView.loadImageUsingCacheWithURLString(user!.getImageUrl(), completion: { result in })
            usernameLabel.text = user!.getDisplayName()
            
            usernameLabel.textColor = UIColor.whiteColor()
            profileImageView.layer.borderWidth = 1.0
            profileImageView.layer.borderColor = UIColor.whiteColor().CGColor
            
            status = checkFollowingStatus(user!.uid)
            
            switch status {
            case .CurrentUser:
                friendButton.hidden = true
                break
            case .Following:
                friendButton.hidden = false
                friendButton.setTitle("Following", forState: .Normal)
                friendButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
                friendButton.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
                friendButton.sizeToFit()
                break
            case .None:
                friendButton.hidden = false
                friendButton.setTitle("Follow", forState: .Normal)
                friendButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                friendButton.backgroundColor = accentColor
                friendButton.sizeToFit()
                break
            case .Requested:
                self.hidden = false
                break
            }

            

        }
    }
    
    var location:Location? {
        didSet{
            usernameLabel.textColor = UIColor.whiteColor()
            profileImageView.image = nil
            profileImageView.loadImageUsingCacheWithURLString(location!.getImageURL(), completion: { result in })
            usernameLabel.text = location!.getName()
            profileImageView.layer.borderWidth = 1.0
            profileImageView.layer.borderColor = UIColor.whiteColor().CGColor
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width/6
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width/2
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
        
        
        backgroundColor = UIColor.clearColor()
        
        
        friendButton.layer.cornerRadius = 4
        friendButton.clipsToBounds = true
        friendButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        
    }
    @IBAction func friendButtonTapped(sender: AnyObject) {
        if let user = self.user {
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
    }

}
