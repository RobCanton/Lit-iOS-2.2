
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
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        contentImageView.layer.cornerRadius = contentImageView.frame.width/2
        contentImageView.clipsToBounds = true
        
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    var user:User?
    
    func setupUser(uid:String) {
        contentImageView.image = nil
        
        FirebaseService.getUser(uid, completionHandler: { user in
            if user != nil {
                self.user = user!
                self.contentImageView.loadImageUsingCacheWithURLString(user!.getImageUrl(), completion: { result in })
                self.usernameLabel.text = user!.getDisplayName()
                
            }
        })
    }
}
