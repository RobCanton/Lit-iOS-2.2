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
            profileImageView.loadImageUsingCacheWithURLString(user!.getImageUrl(), completion: { result in })
            usernameLabel.text = user!.getDisplayName()
            if isFriend(user!.getUserId()) {
                usernameLabel.textColor = accentColor
                profileImageView.layer.borderWidth = 2.0
                profileImageView.layer.borderColor = accentColor.CGColor
            } else {
                usernameLabel.textColor = UIColor.whiteColor()
                profileImageView.layer.borderWidth = 2.0
                profileImageView.layer.borderColor = UIColor.whiteColor().CGColor
            }
        }
    }
    
    var location:Location? {
        didSet{
            usernameLabel.textColor = UIColor.whiteColor()
            profileImageView.loadImageUsingCacheWithURLString(location!.getImageURL(), completion: { result in })
            usernameLabel.text = location!.getName()
            profileImageView.layer.borderWidth = 2.0
            profileImageView.layer.borderColor = UIColor.whiteColor().CGColor
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        profileImageView.layer.cornerRadius = profileImageView.frame.width/2
        profileImageView.clipsToBounds = true
        
        
        selectionStyle = .None
        
        backgroundColor = UIColor.clearColor()
        
    }


}
