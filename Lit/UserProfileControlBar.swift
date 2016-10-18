//
//  UserProfileControlBar.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

protocol ControlBarProtocol {
    func friendBlockTapped()
}

class UserProfileControlBar: UIView {

    @IBOutlet weak var leftBlock: UIView!
    @IBOutlet weak var centerBlock: UIView!
    @IBOutlet weak var rightBlock: UIView!

    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var centerLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    
    var delegate:ControlBarProtocol?
    
    var friendBlockTap:UITapGestureRecognizer!
    
    func setControlBar() {
        friendBlockTap = UITapGestureRecognizer(target: self, action: #selector(friendBlockTapped))
        centerBlock.userInteractionEnabled = true
        centerBlock.addGestureRecognizer(friendBlockTap)
        //leftLabel.styleProfileBlockText(130, text: "Reputation", color: UIColor.whiteColor())
        
        self.layer.borderWidth = 1.5
        self.layer.borderColor = UIColor.blackColor().CGColor
    }
    
    func setFriendsBlock(numFriends:Int) {
        if numFriends != 1 {
           centerLabel.styleProfileBlockText(numFriends, text: "Friends", color: UIColor.whiteColor())
        } else {
            centerLabel.styleProfileBlockText(numFriends, text: "Friend", color: UIColor.whiteColor())
        }
    }
    
    func setPostsBlock(numPosts:Int) {
        if numPosts != 1 {
            leftLabel.styleProfileBlockText(numPosts, text: "Posts", color: UIColor.whiteColor())
        } else {
            leftLabel.styleProfileBlockText(numPosts, text: "Post", color: UIColor.whiteColor())
        }
    }
    
    func friendBlockTapped(gesture:UITapGestureRecognizer) {
        delegate?.friendBlockTapped()
    }
}
