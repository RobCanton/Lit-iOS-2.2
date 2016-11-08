//
//  CreateProfileHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-06.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import Firebase

protocol HeaderProtocol {
    func backTapped()
    func messageTapped()
}

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
    
    @IBOutlet weak var backBtn: UIButton!
    var friendBtnTap:UITapGestureRecognizer!
    var messageBtnTap:UITapGestureRecognizer!
    
    
    var delegate:HeaderProtocol!
    var user:User!

    @IBAction func backTapped(sender: AnyObject) {
        delegate.backTapped()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [UIColor.clearColor().CGColor, UIColor(white: 0.0, alpha: 0.75).CGColor]
        gradient.locations = [0.0 , 1.0]
        
        gradient.frame = gradientView.bounds
        gradientView.layer.insertSublayer(gradient, atIndex: 0)
        
        messageBtn.layer.cornerRadius = messageBtn.frame.height/2
        friendBtn.layer.cornerRadius = messageBtn.frame.height/3
        
        friendBtnTap = UITapGestureRecognizer(target: self, action: #selector(friendBtnTapped))
        messageBtnTap = UITapGestureRecognizer(target: self, action: #selector(messageBtnTapped))
    }
    
    func populateUser(user:User) {
        self.user = user
        usernameLabel.text = user.getDisplayName()

        FirebaseService.ref.child("users/lastLocation/\(user.getUserId())").observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            var string = "Unknown"

            if snapshot.exists() {
                print(snapshot)
                let key = snapshot.value! as! String
                for city in mainStore.state.cities {
                    if key == city.getKey() {
                        string = "\(city.getName()), \(city.getRegion()), \(city.getCountry())"

                    }
                }
            }
            
            self.locationLabel.text     = string
        })
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
            friendBtn.alpha = 1 + progress * 1.75
            backBtn.alpha = 1 + progress * 1.75
            
        }
    }
    
    func friendBtnTapped(gesture:UITapGestureRecognizer) {
        friendBtn.removeGestureRecognizer(friendBtnTap)

        print("Tapped:\(status.rawValue)")
        switch status {
        case .FRIENDS:
            break
        case .NOT_FRIENDS:
            FirebaseService.sendFriendRequest(user.getUserId(), completionHandler: { success in})
            break
        case .PENDING_INCOMING:
            FirebaseService.acceptFriendRequest(user.getUserId())
            break
        case .PENDING_INCOMING_SEEN:
            FirebaseService.acceptFriendRequest(user.getUserId())
            break
        case .PENDING_OUTGOING:
            break
        default:
            break
        }
    }
    
    
    
    func messageBtnTapped(gesture:UITapGestureRecognizer) {
        delegate.messageTapped()
    }
    
    var status:FriendStatus = .NOT_FRIENDS
    
    
    func animateDown() {
        UIView.animateWithDuration(0.15, animations: {
            self.alpha = 0.6
        })
    }
    
    func animateUp() {
        UIView.animateWithDuration(0.3, animations: {
            self.alpha = 1.0
        })
    }
    
    func checkFriendStatus() {
//        status = FirebaseService.checkFriendStatus(user.getUserId())
//        switch status {
//        case .IS_CURRENT_USER:
//            friendBtn.hidden = true
//            messageBtn.hidden = true
//            break
//        case .FRIENDS:
//            friendBtnImage.setImage(UIImage(named: "checkmark_filled"), forState: .Normal)
//            friendBtnLabel.text = "Friends"
//            friendBtn.backgroundColor = UIColor(white: 0.5, alpha: 1.0)
//            friendBtn.hidden = false
//            messageBtn.hidden = false
//            break
//        case .NOT_FRIENDS:
//            
//            friendBtnImage.setImage(UIImage(named: "plus_plain"), forState: .Normal)
//            friendBtnLabel.text = "Add Friend"
//            friendBtn.backgroundColor = accentColor
//            friendBtn.hidden = false
//            messageBtn.hidden = false
//            break
//        case .PENDING_INCOMING:
//            friendBtnImage.setImage(UIImage(named: "plus_plain"), forState: .Normal)
//            friendBtnLabel.text = "Accept"
//            friendBtn.backgroundColor = accentColor
//            friendBtn.hidden = false
//            messageBtn.hidden = false
//            break
//        case .PENDING_INCOMING_SEEN:
//            friendBtnImage.setImage(UIImage(named: "plus_plain"), forState: .Normal)
//            friendBtnLabel.text = "Accept"
//            friendBtn.backgroundColor = accentColor
//            friendBtn.hidden = false
//            messageBtn.hidden = false
//            break
//        case .PENDING_OUTGOING:
//            friendBtnImage.setImage(UIImage(named: "plus_plain"), forState: .Normal)
//            friendBtnLabel.text = "Added"
//            friendBtn.backgroundColor = UIColor(white: 0.5, alpha: 1.0)
//            friendBtn.hidden = false
//            messageBtn.hidden = false
//            break
//        }
//        
//        friendBtn.addGestureRecognizer(friendBtnTap)
//        messageBtn.addGestureRecognizer(messageBtnTap)
        
    }
}
