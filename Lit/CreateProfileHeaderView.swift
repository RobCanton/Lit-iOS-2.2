//
//  CreateProfileHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-06.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class CreateProfileHeaderView: UIView {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var gradientView: UIView!
    
    func setGradient() {
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().CGColor]
        gradient.locations = [0.0 , 1.0]
        
        gradient.frame = gradientView.bounds
        gradientView.layer.insertSublayer(gradient, atIndex: 0)
    }
    
}
