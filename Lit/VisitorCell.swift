//
//  VisitorCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-07.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import BRYXBanner

class VisitorCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    @IBAction func addFriendButton(sender: UIButton) {

    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBOutlet var visitorImage: UIImageView!
    
    @IBOutlet var visitorName: UILabel!
    
    @IBOutlet var addFriendBtn: UIButton!
    var user:User?
    var friendStatus:FriendStatus = FriendStatus.NOT_FRIENDS
    
    func set(visitor_uid:String) {
        friendStatus = FriendStatus.NOT_FRIENDS
        addFriendBtn.hidden = true
        addFriendBtn.enabled = false
        addFriendBtn.tintColor = UIColor.whiteColor()

        let backView = UIView()
        backView.backgroundColor = UIColor.clearColor()
        self.backgroundView = backView
        self.backgroundColor = UIColor.clearColor()
        
        visitorImage.layer.cornerRadius = visitorImage!.frame.size.width / 2;
        visitorImage.clipsToBounds = true;
        
        FirebaseService.getUser(visitor_uid, completionHandler: {_user in
            if let user = _user {
                self.user = user
                self.visitorImage.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in
                })
                self.visitorName.text = user.getDisplayName()
            }
        })

    }
    
}
