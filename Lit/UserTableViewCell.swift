//
//  UserTableViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {


    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    var user:User? {
        didSet{
            profileImageView.image = nil
            profileImageView.loadImageUsingCacheWithURLString(user!.getImageUrl(), completion: { result in })
            usernameLabel.text = user!.getDisplayName()
            if isFriend(user!.getUserId()) {
                usernameLabel.textColor = accentColor
                profileImageView.layer.borderWidth = 1.0
                profileImageView.layer.borderColor = accentColor.CGColor
            } else {
                usernameLabel.textColor = UIColor.whiteColor()
                profileImageView.layer.borderWidth = 1.0
                profileImageView.layer.borderColor = UIColor.whiteColor().CGColor
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
        
    }


}
