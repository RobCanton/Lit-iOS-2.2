//
//  CreateProfileHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-06.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import Firebase


class CreateProfileHeaderView: UIView {
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationIcon: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var bioTextView: UILabel!

    var user:User!

    override func awakeFromNib() {
        super.awakeFromNib()
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [UIColor.clearColor().CGColor, UIColor(white: 0.0, alpha: 0.75).CGColor]
        gradient.locations = [0.0 , 1.0]
        
        gradient.frame = gradientView.bounds
        gradientView.layer.insertSublayer(gradient, atIndex: 0)
        
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

        }
    }
 
    var status:FriendStatus = .NOT_FRIENDS
    
    
    func animateDown() {
        UIView.animateWithDuration(0.5, animations: {
            self.imageView.alpha = 0.6
        })
    }
    
    func animateUp() {
        UIView.animateWithDuration(0.15, animations: {
            self.imageView.alpha = 1.0
        })
    }
}
