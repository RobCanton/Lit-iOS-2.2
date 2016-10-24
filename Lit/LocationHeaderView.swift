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
}

class LocationHeaderView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var locationTitle: UILabel!
    @IBOutlet weak var addressTitle: UILabel!
    
    @IBOutlet weak var addressBlock: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    var delegate:LocationHeaderProtocol?
    
    var addressTap:UITapGestureRecognizer!
    
    @IBAction func backTapped(sender: AnyObject) {
        delegate?.backTapped()
    }
    
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
            addressBlock.alpha = 1 + progress * 1.75
            descriptionLabel.alpha = 1 + progress * 1.75
        }
    }
    
    func setLocation(location:Location) {
        
        imageView.loadImageUsingCacheWithURLString(location.getImageURL(), completion: { result in })
        locationTitle.styleLocationTitle(location.getName(), size: 32.0)
        locationTitle.applyShadow(4, opacity: 0.8, height: 4, shouldRasterize: false)
        addressTitle.text = location.getAddress()
        descriptionLabel.text = location.getDescription()
        
        addressTap = UITapGestureRecognizer(target: self, action: #selector(showMap))
        addressBlock.userInteractionEnabled = true
        addressBlock.addGestureRecognizer(addressTap)
    }
    
    func showMap(gesture:UITapGestureRecognizer) {
        delegate?.showMap()
    }

}
