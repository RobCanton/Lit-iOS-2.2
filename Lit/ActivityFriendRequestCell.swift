//
//  ActivityFriendRequestCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class ActivityFriendRequestCell: UITableViewCell {


    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var addFriendBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    
    @IBOutlet weak var userNameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    var friend_uid:String!

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func set(friend_uid:String) {
        self.friend_uid = friend_uid
        userImage.layer.cornerRadius = userImage!.frame.size.width / 2;
        userImage.clipsToBounds = true;
        
        addFriendBtn.layer.cornerRadius = 1
        addFriendBtn.clipsToBounds = true;
        
        deleteBtn.layer.borderColor = UIColor.whiteColor().CGColor
        deleteBtn.layer.borderWidth = 1.0
        deleteBtn.layer.cornerRadius = 1
        deleteBtn.clipsToBounds = true;

        
        FirebaseService.getUser(friend_uid ,  completionHandler: {_user in
            if let user = _user {
                print(user.getDisplayName())
                self.userImage.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in
                    
                })
                self.userNameLabel.text = user.getDisplayName()
            }
        })
    }
    @IBAction func confirmTapped(sender: AnyObject) {
        print("Confirm")
        FirebaseService.acceptFriendRequest(friend_uid)

    }
    @IBAction func deleteTapped(sender: AnyObject) {
        print("Delete")
    }
    
}
