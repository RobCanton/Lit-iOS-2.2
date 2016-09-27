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
            if friendStatus == .NOT_FRIENDS {
                let userRef = FirebaseService.ref.child("users/\(uid)/friendRequests")
                userRef.child(_user.getUserId())
                    .setValue([
                        "status": FriendStatus.PENDING_OUTGOING.rawValue
                        ])
                let friendRef = FirebaseService.ref.child("users/\(_user.getUserId())/friendRequests/\(uid)")
                friendRef.setValue([
                    "status": FriendStatus.PENDING_INCOMING.rawValue
                    ], withCompletionBlock: {
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
            } else if friendStatus == .PENDING_INCOMING {
                FirebaseService.ref.child("users/\(uid)/friendRequests/\(_user.getUserId())").removeValue()
                FirebaseService.ref.child("users/\(_user.getUserId())/friendRequests/\(uid)").removeValue()
                FirebaseService.ref.child("users/\(uid)/friends/\(_user.getUserId())").setValue(true)
                FirebaseService.ref.child("users/\(_user.getUserId())/friends/\(uid)").setValue(true)
            }
            
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
    var friendStatus:FriendStatus = FriendStatus.NOT_FRIENDS
    
    func set(visitor_uid:String) {
        
        addFriendBtn.enabled = false
        addFriendBtn.tintColor = UIColor.whiteColor()

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
        
        /*  THIS IS VERY COSTLY */
        /*  LOOK FOR NEW SOLUTION */
        let requests = mainStore.state.userState.friendRequests
        for request in requests {
            if request.getId() == visitor_uid {
                friendStatus = FriendStatus.PENDING_INCOMING
            }
        }
        
        let requestsOut = mainStore.state.userState.friendRequestsOut
        for requestOut in requestsOut {
            if requestOut.getId() == visitor_uid {
                friendStatus = FriendStatus.PENDING_OUTGOING
            }
        }
        let friends = mainStore.state.userState.friends
        for friend in friends {
            if friend.getId() == visitor_uid {
                friendStatus = FriendStatus.FRIENDS
            }
        }
        
        switch friendStatus {
        case .PENDING_INCOMING:
            addFriendBtn.tintColor = accentColor
            addFriendBtn.enabled = true
            break
        case .PENDING_OUTGOING:
            addFriendBtn.tintColor = accentColor
            addFriendBtn.enabled = false
            break
        case .FRIENDS:
            addFriendBtn.tintColor = accentColor
            addFriendBtn.imageView!.image = UIImage(named: "ok")
            addFriendBtn.enabled = false
            visitorName.textColor = accentColor
            break
        case .NOT_FRIENDS:
            addFriendBtn.tintColor = UIColor.whiteColor()
            addFriendBtn.enabled = true
            break
        default:
            break
        }
        

        
    }
    
    
}
