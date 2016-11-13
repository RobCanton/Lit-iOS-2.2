//
//  FollowButton.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift



class FollowButton: UIButton {
    
    var status:FollowingStatus = FollowingStatus.None
    var _user:User?

    
    func setFollowButton(){
        self.hidden = true
        
        self.titleLabel!.font = UIFont(name: "Avenir-Medium", size: 15.0)
        self.layer.cornerRadius = 5
        self.clipsToBounds = true
        self.contentEdgeInsets = UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)
        self.sizeToFit()
        self.addTarget(self, action: #selector(down), forControlEvents: .TouchDown)
        self.addTarget(self, action: #selector(tapped), forControlEvents: .TouchUpInside)
    }
    
    func down(sender:UIButton) {
        self.alpha = 0.5
    }
    
    func tapped(sender:UIButton) {
        self.alpha = 1.0
        if let user = _user {
            switch status {
            case .CurrentUser:
                break
            case .Following:
                SocialService.unfollowUser(user.getUserId())
                break
            case .None:
                SocialService.followUser(user.getUserId())
                break
            case .Requested:
                break
            }
        }
    }
    
    func setUser(user:User) {
        _user   = user
        status = checkFollowingStatus(_user!.uid)
        
        switch status {
        case .CurrentUser:
            self.hidden = true
            break
        case .Following:
            self.hidden = false
            self.setTitle("Following", forState: .Normal)
            self.setTitleColor(UIColor.blackColor(), forState: .Normal)
            self.backgroundColor = UIColor.whiteColor()
            self.sizeToFit()
            break
        case .None:
            self.hidden = false
            self.setTitle("+ Follow", forState: .Normal)
            self.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            self.backgroundColor = accentColor
            self.sizeToFit()
            break
        case .Requested:
            self.hidden = false
            break
        }
        
    }



}
