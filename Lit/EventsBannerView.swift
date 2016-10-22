//
//  EventsBannerView.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-22.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class EventsBannerView: UIView {
    
    @IBOutlet weak var gradientView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [UIColor.clearColor().CGColor, UIColor(white: 0.0, alpha: 0.8).CGColor]
        gradient.locations = [0.0 , 1.0]
        
        gradient.frame = gradientView.bounds
        gradientView.layer.insertSublayer(gradient, atIndex: 0)
        
        self.layer.borderColor = UIColor.blackColor().CGColor
        self.layer.borderWidth = 1.0
        
    }

}
