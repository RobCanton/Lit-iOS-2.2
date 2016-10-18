//
//  LocationHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-17.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class LocationHeaderView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var gradientView: UIView!
    
    var delegate:HeaderProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [UIColor.clearColor().CGColor, UIColor(white: 0.0, alpha: 0.75).CGColor]
        gradient.locations = [0.0 , 1.0]
        
        gradient.frame = gradientView.bounds
        gradientView.layer.insertSublayer(gradient, atIndex: 0)
    }
    
    func setProgress(progress:CGFloat) {
        if progress < 0 {
        }
    }
    
    func setLocation(location:Location) {
        
        imageView.loadImageUsingCacheWithURLString(location.getImageURL(), completion: { result in })
        
    }

}
