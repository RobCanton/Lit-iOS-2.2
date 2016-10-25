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
    
    @IBOutlet weak var guestsView: UIView!
    var addressTap:UITapGestureRecognizer!
    
    @IBAction func backTapped(sender: AnyObject) {
        delegate?.backTapped()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [UIColor.clearColor().CGColor, UIColor(white: 0.0, alpha: 0.85).CGColor]
        gradient.locations = [0.0 , 1.0]
        
        gradient.frame = gradientView.bounds
        gradientView.layer.insertSublayer(gradient, atIndex: 0)
        
        setGuests()
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
    
    func setGuests() {
        
        let numGuests = 3
        
        for i in 0 ..< numGuests {
            let image = UIImage(named: "11")
            let profileView = UIImageView(image: image)
            profileView.backgroundColor = UIColor.blackColor()
            let size = guestsView.frame.height
            profileView.frame = CGRectMake(CGFloat(i) * size * 0.75, 0, size, size)
            profileView.layer.cornerRadius = profileView.frame.width/2
            profileView.clipsToBounds = true
            guestsView.addSubview(profileView)
            guestsView.sendSubviewToBack(profileView)
//            let x = (CGFloat(i) * (profileView.frame.width * (0.75 - (0.02 * CGFloat(i)))))
//            profileView.center = CGPointMake(x, guestsView.center.y/2)
//            guestsView.addSubview(profileView)
            //guestsView.sendSubviewToBack(profileView)
        }
        
        let label = UILabel()
        label.text = "3 friends are here"
        label.font = UIFont(name: "Avenir-Medium", size: 22.0)
        
    }

}
