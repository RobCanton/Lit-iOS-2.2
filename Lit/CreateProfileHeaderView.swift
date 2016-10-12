//
//  CreateProfileHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-06.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class CreateProfileHeaderView: UIView {
    
    @IBOutlet weak var centerUsernameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var gradientView: UIView!
    
    @IBOutlet weak var bioTextView: UILabel!
    func setGradient() {
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [UIColor.clearColor().CGColor, UIColor(white: 0.0, alpha: 0.75).CGColor]
        gradient.locations = [0.0 , 1.0]
        
        gradient.frame = gradientView.bounds
        gradientView.layer.insertSublayer(gradient, atIndex: 0)
    }
    
    func setUsername(name:String) {
        usernameLabel.text = name
        centerUsernameLabel.text = name
        
        bioTextView.text = "holy crap i mean i know i can write a lot but like, i didnt know i could right this much, like this really is a lot of text"
    }
    
    
    func setProgress(progress:CGFloat) {
        if progress < 0 {
            //titleLabel.alpha = alpha
            usernameLabel.alpha = 1 + progress * 1.5
            bioTextView.alpha = 1 + progress * 1.5
            //centerUsernameLabel.alpha = 1 - usernameLabel.alpha
            
        }
    }
}
