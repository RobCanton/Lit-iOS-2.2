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
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        profileImageView.layer.cornerRadius = profileImageView.frame.width/2
        profileImageView.clipsToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
