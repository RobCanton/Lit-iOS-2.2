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
    
    var status:FriendStatus = FriendStatus.NOT_FRIENDS
    
    var user:User? {
        didSet{
            profileImageView.image = nil
            profileImageView.loadImageUsingCacheWithURLString(user!.getImageUrl(), completion: { result in })
            usernameLabel.text = user!.getDisplayName()
            
            usernameLabel.textColor = UIColor.whiteColor()
            profileImageView.layer.borderWidth = 1.0
            profileImageView.layer.borderColor = UIColor.whiteColor().CGColor
            
            status = checkFriendStatus(user!.getUserId())
            switch status {
            case .IS_CURRENT_USER:
                friendButton.hidden = true
                friendButton.enabled = false
                break
            case .FRIENDS:
                friendButton.setTitle("friends", forState: .Normal)
                friendButton.backgroundColor = UIColor.darkGrayColor()
                friendButton.enabled = false
                break
            case .NOT_FRIENDS:
                friendButton.setTitle("+ add", forState: .Normal)
                friendButton.backgroundColor = accentColor
                friendButton.enabled = true
                break
            case .PENDING_INCOMING:
                friendButton.setTitle("+ confirm", forState: .Normal)
                friendButton.backgroundColor = accentColor
                friendButton.enabled = true
                break
            case .PENDING_INCOMING_SEEN:
                friendButton.setTitle("+ confirm", forState: .Normal)
                friendButton.backgroundColor = accentColor
                friendButton.enabled = true
                break
            case .PENDING_OUTGOING:
                friendButton.setTitle("added", forState: .Normal)
                friendButton.backgroundColor = UIColor.darkGrayColor()
                friendButton.enabled = false
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
        
        selectionStyle = .None
        
        backgroundColor = UIColor.clearColor()
        
        
        friendButton.layer.cornerRadius = 5
        friendButton.clipsToBounds = true
        friendButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        
    }
    @IBAction func friendButtonTapped(sender: AnyObject) {
        FirebaseService.handleFriendAction(user!.getUserId(), status: status)
    }

}
