//
//  LocationHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-17.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

protocol LocationHeaderProtocol {
    func backTapped()
    func showMap()
    func showGuests()
}

class LocationHeaderView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var locationTitle: UILabel!
    @IBOutlet weak var addressTitle: UILabel!
    
    @IBOutlet weak var fadeCover: UIView!

    var delegate:LocationHeaderProtocol?
    
    var addressTap:UITapGestureRecognizer!
    
    @IBAction func backTapped(sender: AnyObject) {
        delegate?.backTapped()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [UIColor.clearColor().CGColor, UIColor(white: 0.0, alpha: 0.5).CGColor]
        gradient.locations = [0.0 , 1.0]
        
        gradient.frame = gradientView.bounds
        gradientView.layer.insertSublayer(gradient, atIndex: 0)
        
    }
    
    func setProgress(progress:CGFloat) {
        if progress < -0.4 {
            let p = abs(progress)
            fadeCover.alpha = ((p - 0.4) / 0.6) * 1.75
        } else {
            fadeCover.alpha = 0
        }
    }
    var location:Location?
    func setHeaderLocation(location:Location) {
        self.location = location
        
        imageView.loadImageUsingCacheWithURLString(location.getImageURL(), completion: { result in })
        locationTitle.styleLocationTitle(location.getName(), size: 32.0)
        locationTitle.applyShadow(2, opacity: 0.8, height: 2, shouldRasterize: false)

    }
    
    func showMap(gesture:UITapGestureRecognizer) {
        delegate?.showMap()
    }
    
    func showGuests(gesture:UITapGestureRecognizer) {
        delegate?.showGuests()
    }
    
}
