//
//  CreateProfileHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-06.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class CreateProfileHeaderView: UIView {
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationIcon: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var bioTextView: UILabel!
    
    @IBOutlet weak var messageBtn: UIView!

    @IBOutlet weak var friendBtn: UIView!
    @IBOutlet weak var friendBtnImage: UIButton!
    @IBOutlet weak var friendBtnLabel: UILabel!
    
    func setGradient() {
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [UIColor.clearColor().CGColor, UIColor(white: 0.0, alpha: 0.75).CGColor]
        gradient.locations = [0.0 , 1.0]
        
        gradient.frame = gradientView.bounds
        gradientView.layer.insertSublayer(gradient, atIndex: 0)
        
        messageBtn.layer.cornerRadius = messageBtn.frame.height/2
        friendBtn.layer.cornerRadius = messageBtn.frame.height/3
        

    }
    
    func setUsername(name:String) {
        usernameLabel.text = name
        
        bioTextView.text = "Tell me, who did I leave behind. You think it got to me. I can just read your mind. You think I'm so caught up in where I am right now."
    }
    
    
    func setProgress(progress:CGFloat) {
        if progress < 0 {
            //titleLabel.alpha = alpha
            usernameLabel.alpha = 1 + progress * 1.75
            bioTextView.alpha = 1 + progress * 1.75
            locationIcon.alpha = 1 + progress * 1.75
            locationLabel.alpha = 1 + progress * 1.75
            messageBtn.alpha = 1 + progress * 1.75
            friendBtn.alpha = 1 + progress * 1.75
            //centerUsernameLabel.alpha = 1 - usernameLabel.alpha
            
        }
    }
    
    func setFriendStatus(status:FriendStatus) {
        switch status {
        case .FRIENDS:
            friendBtnImage.setImage(UIImage(named: "checkmark"), forState: .Normal)
            friendBtnLabel.text = "Friends"
            friendBtn.backgroundColor = UIColor(white: 0.45, alpha: 1.0)
            break
        case .NOT_FRIENDS:
            friendBtnImage.setImage(UIImage(named: "plus_plain"), forState: .Normal)
            friendBtnLabel.text = "Add Friend"
            friendBtn.backgroundColor = accentColor
            break
        case .PENDING_INCOMING:
            friendBtnImage.setImage(UIImage(named: "plus_plain"), forState: .Normal)
            friendBtnLabel.text = "Add Friend"
            friendBtn.backgroundColor = accentColor
            break
        case .PENDING_INCOMING_SEEN:
            friendBtnImage.setImage(UIImage(named: "plus_plain"), forState: .Normal)
            friendBtnLabel.text = "Add Friend"
            friendBtn.backgroundColor = accentColor
            break
        case .PENDING_OUTGOING:
            friendBtnImage.setImage(UIImage(named: "plus_plain"), forState: .Normal)
            friendBtnLabel.text = "Added"
            friendBtn.backgroundColor = UIColor(white: 0.45, alpha: 1.0)
            break
        default:
            break
        }
    }
}
