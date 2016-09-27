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
    
    var friend:Friend?

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func set(_friend:Friend) {
        friend = _friend
        userImage.layer.cornerRadius = userImage!.frame.size.width / 2;
        userImage.clipsToBounds = true;
        
        addFriendBtn.layer.cornerRadius = 1
        addFriendBtn.clipsToBounds = true;
        
        deleteBtn.layer.borderColor = UIColor.whiteColor().CGColor
        deleteBtn.layer.borderWidth = 1.0
        deleteBtn.layer.cornerRadius = 1
        deleteBtn.clipsToBounds = true;
        print("FRIEND ID: " + friend!.getId())
        
        FirebaseService.getUser(friend!.getId() ,  completionHandler: {user in
            print(user.getDisplayName())
            self.userImage.loadImageUsingCacheWithURLString(user.getImageUrl()!, completion: { result in
            
            })
            self.userNameLabel.text = user.getDisplayName()!
        })
    }
    @IBAction func confirmTapped(sender: AnyObject) {
        print("Confirm")
        let uid = mainStore.state.userState.uid
        let ref = FirebaseService.ref.child("users/\(uid)/friendRequests_in")
        ref.child(friend!.getId()).removeValue()
        
        let outRef = FirebaseService.ref.child("users/\(friend!.getId())/friendRequests_out")
        outRef.child(uid).removeValue()
    }
    @IBAction func deleteTapped(sender: AnyObject) {
        print("Delete")
    }
    
}
