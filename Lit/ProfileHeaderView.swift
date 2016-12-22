//
//  ProfileHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class ProfileHeaderView: UICollectionReusableView {

    
    @IBOutlet weak var controlBarContainer: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var bioLabel: UILabel!
    
    @IBOutlet weak var followingLabel: UILabel!

    @IBOutlet weak var followersLabel: UILabel!
    
    @IBOutlet weak var postsLabel: UILabel!
    
    @IBOutlet weak var messageBtn: UIButton!
    
    @IBOutlet weak var followButton: UIButton!
    let subColor = UIColor(white: 0.4, alpha: 1.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code


    }
    
    func populateHeader(user:User){
        loadImageUsingCacheWithURL(user.getLargeImageUrl(), completion: { image in
            self.profileImageView.image = image
        })
        postsLabel.styleProfileBlockText(13, text: "posts", color: subColor, color2: UIColor.whiteColor())
        followersLabel.styleProfileBlockText(158, text: "followers", color: subColor, color2: UIColor.whiteColor())
        followingLabel.styleProfileBlockText(87, text: "following", color: subColor, color2: UIColor.whiteColor())
        
//        followersLabel.center = CGPoint(x: (followingLabel.center.x - postsLabel.center.x) / 2 + postsLabel.center.x, y: postsLabel.center.y)
//        
        followButton.layer.cornerRadius = 2.0
        followButton.clipsToBounds = true
        
        messageBtn.layer.cornerRadius = 2.0
        messageBtn.clipsToBounds = true
        
//        followButton.superview!.layer.borderWidth = 1.0
//        followButton.superview!.layer.borderColor = accentColor.CGColor
//        //followButton.tintColor = accentColor
//        
        messageBtn.layer.borderWidth = 1.0
        messageBtn.layer.borderColor = UIColor.whiteColor().CGColor
        messageBtn.tintColor = UIColor.whiteColor()
        
//        let controlBar = UINib(nibName: "UserProfileControlBarView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! UserProfileControlBar
//        controlBar.frame = controlBarContainer.bounds
//        controlBar.setControlBar()
//        controlBarContainer?.addSubview(controlBar)

        
        bioLabel.text = "MORE LIFE. MORE CHUNES.\nTop of 2017.\n\nOVOXO."
    }
    
}
