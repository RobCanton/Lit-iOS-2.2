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
        if let _user = user {
            //sender.setImage(UIImage(named: "wait"), forState: .Normal)
            sender.enabled = false
            
            let uid = mainStore.state.userState.uid
            let userRef = FirebaseService.ref.child("users/\(uid)/friendRequests_out")
            userRef.child(_user.getUserId()).setValue(true)
            
            let friendRef = FirebaseService.ref.child("users/\(_user.getUserId())")
            friendRef.child("friendRequests_in/\(uid)").setValue(true, withCompletionBlock: {
                error, ref in
                
                if error != nil {
                    sender.enabled = true
                    let banner = Banner(title: "Unable to send friend request", subtitle: "Please try again later.", image: UIImage(named: "error"), backgroundColor: errorColor)
                    banner.dismissesOnTap = true
                    banner.show(duration: 5.0)
                } else {
                    let banner = Banner(title: _user.getDisplayName(), subtitle: "Friend request sent!", image: UIImage(named: "thumbsup"), backgroundColor: accentColor)
                    banner.dismissesOnTap = true
                    banner.show(duration: 3.0)
                }
            })
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBOutlet var visitorImage: UIImageView!
    
    @IBOutlet var visitorName: UILabel!
    
    @IBOutlet var addFriendBtn: UIButton!
    var user:User?
    
    func set(visitor_uid:String) {
        
        addFriendBtn.enabled = false
        let uid = mainStore.state.userState.uid
        let ref = FirebaseService.ref.child("users/\(uid)/friendRequests_out/\(visitor_uid)")
        ref.observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.exists() {
                self.addFriendBtn.enabled = false
            } else {
                self.addFriendBtn.enabled = true
            }
        })
        
        let backView = UIView()
        backView.backgroundColor = UIColor.clearColor()
        self.backgroundView = backView
        self.backgroundColor = UIColor.clearColor()
        
        visitorImage.layer.cornerRadius = visitorImage!.frame.size.width / 2;
        visitorImage.clipsToBounds = true;

        FirebaseService.getUser(visitor_uid, completionHandler: {user in
            print(user.getDisplayName())
            self.user = user
            self.visitorImage.loadImageUsingCacheWithURLString(user.getImageUrl()!, completion: { result in
            })
            self.visitorName.text = user.getDisplayName()!
        })

        
        
    }
}
