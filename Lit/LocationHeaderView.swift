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
    
    @IBOutlet weak var addressBlock: UIView!
    var delegate:LocationHeaderProtocol?
    
    var addressTap:UITapGestureRecognizer!
    
    @IBOutlet weak var guestsView: UIView!
    
    @IBOutlet weak var guestsLabel: UILabel!
    
    
    var centerTap: UITapGestureRecognizer!
    var leftTap: UITapGestureRecognizer!
    var rightTap: UITapGestureRecognizer!
    var labelTap: UITapGestureRecognizer!
    var leftGuest:UIImageView!
    var centerGuest:UIImageView!
    var rightGuest:UIImageView!
    
    
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
        
        let size = guestsView.frame.height
        
        centerGuest = UIImageView()
        centerGuest.backgroundColor = UIColor.blackColor()
        centerGuest.frame = CGRectMake(0, 0, size * 1.05, size * 1.05)
        centerGuest.layer.cornerRadius = centerGuest.frame.width/2
        centerGuest.clipsToBounds = true
        
        leftGuest = UIImageView()
        leftGuest.backgroundColor = UIColor.blackColor()
        leftGuest.frame = CGRectMake(0, 0, size, size)
        leftGuest.layer.cornerRadius = leftGuest.frame.width/2
        leftGuest.clipsToBounds = true
        
        rightGuest = UIImageView()
        rightGuest.backgroundColor = UIColor.blackColor()
        rightGuest.frame = CGRectMake(0, 0, size, size)
        rightGuest.layer.cornerRadius = rightGuest.frame.width/2
        rightGuest.clipsToBounds = true
        
        centerGuest.layer.borderColor = UIColor.whiteColor().CGColor
        centerGuest.layer.borderWidth = 0.75
        leftGuest.layer.borderColor = UIColor.whiteColor().CGColor
        leftGuest.layer.borderWidth = 0.75
        rightGuest.layer.borderColor = UIColor.whiteColor().CGColor
        rightGuest.layer.borderWidth = 0.75
        
        centerGuest.userInteractionEnabled = true
        leftGuest.userInteractionEnabled = true
        rightGuest.userInteractionEnabled = true
        guestsLabel.userInteractionEnabled = true
        
        guestsView.addSubview(leftGuest)
        guestsView.addSubview(rightGuest)
        guestsView.addSubview(centerGuest)
        
        centerTap = UITapGestureRecognizer(target: self, action: #selector(showGuests))
        leftTap = UITapGestureRecognizer(target: self, action: #selector(showGuests))
        rightTap = UITapGestureRecognizer(target: self, action: #selector(showGuests))
        labelTap = UITapGestureRecognizer(target: self, action: #selector(showGuests))

    }
    
    func setProgress(progress:CGFloat) {
        if progress < 0 {
            addressBlock.alpha = 1 + progress * 1.75
            guestsView.alpha = 1 + progress * 1.75
            guestsLabel.alpha = 1 + progress * 1.75
        }
    }
    var location:Location?
    func setLocation(location:Location) {
        self.location = location
        
        imageView.loadImageUsingCacheWithURLString(location.getImageURL(), completion: { result in })
        locationTitle.styleLocationTitle(location.getName(), size: 32.0)
        locationTitle.applyShadow(4, opacity: 0.8, height: 4, shouldRasterize: false)
        addressTitle.text = location.getAddress()
        
        addressTap = UITapGestureRecognizer(target: self, action: #selector(showMap))
        addressBlock.userInteractionEnabled = true
        addressBlock.addGestureRecognizer(addressTap)
        
        centerGuest.addGestureRecognizer(centerTap)
        leftGuest.addGestureRecognizer(leftTap)
        rightGuest.addGestureRecognizer(rightTap)
        guestsLabel.addGestureRecognizer(labelTap)
    }
    
    func showMap(gesture:UITapGestureRecognizer) {
        delegate?.showMap()
    }
    
    func showGuests(gesture:UITapGestureRecognizer) {
        delegate?.showGuests()
    }
    
    func setGuests() {
        guard let _ = location else { return }
        
        let size = guestsView.frame.height
        let visitors = location!.getVisitors()
        
        let count = visitors.count
        if count == 1 {
            guestsLabel.text = "1 guest"
        } else if count > 1{
            guestsLabel.text = "\(count) guests"
        } else {
            guestsLabel.text = ""
        }
        
        centerGuest.hidden = true
        leftGuest.hidden = true
        rightGuest.hidden = true
        centerGuest.center = CGPointMake(guestsView.center.x - size/4, guestsView.bounds.height/2)
        
        if visitors.count == 1 {
            FirebaseService.getUser(visitors[0], completionHandler: { _user in
                if let user = _user {
                    self.centerGuest.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in })
                }
            })
            centerGuest.hidden = false
            if isFriend(visitors[0]) {
                centerGuest.layer.borderColor = accentColor.CGColor
            } else {
                centerGuest.layer.borderColor = UIColor.whiteColor().CGColor
            }
        }
        if visitors.count == 2 {
            FirebaseService.getUser(visitors[0], completionHandler: { _user in
                if let user = _user {
                    self.leftGuest.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in })
                }
            })
            FirebaseService.getUser(visitors[1], completionHandler: { _user in
                if let user = _user {
                    self.rightGuest.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in })
                }
            })
            leftGuest.hidden = false
            rightGuest.hidden = false
            
            leftGuest.center = CGPointMake(centerGuest.center.x - size * 0.55, guestsView.bounds.height/2)
            rightGuest.center = CGPointMake(centerGuest.center.x + size * 0.55, guestsView.bounds.height/2)
            
            if isFriend(visitors[0]) {
                leftGuest.layer.borderColor = accentColor.CGColor
            } else {
                leftGuest.layer.borderColor = UIColor.whiteColor().CGColor
            }
            if isFriend(visitors[1]) {
                rightGuest.layer.borderColor = accentColor.CGColor
            } else {
                rightGuest.layer.borderColor = UIColor.whiteColor().CGColor
            }
            
        }
        
        if visitors.count >= 3 {
            FirebaseService.getUser(visitors[0], completionHandler: { _user in
                if let user = _user {
                    self.centerGuest.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in })
                }
            })
            FirebaseService.getUser(visitors[1], completionHandler: { _user in
                if let user = _user {
                    self.leftGuest.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in })
                }
            })
            FirebaseService.getUser(visitors[2], completionHandler: { _user in
                if let user = _user {
                    self.rightGuest.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in })
                }
            })
            centerGuest.hidden = false
            leftGuest.hidden = false
            rightGuest.hidden = false
            
            leftGuest.center = CGPointMake(centerGuest.center.x - size * 0.85, guestsView.bounds.height/2)
            rightGuest.center = CGPointMake(centerGuest.center.x + size * 0.85, guestsView.bounds.height/2)
            
            if isFriend(visitors[0]) {
                centerGuest.layer.borderColor = accentColor.CGColor
            } else {
                centerGuest.layer.borderColor = UIColor.whiteColor().CGColor
            }
            
            if isFriend(visitors[1]) {
                leftGuest.layer.borderColor = accentColor.CGColor
            } else {
                leftGuest.layer.borderColor = UIColor.whiteColor().CGColor
            }
            if isFriend(visitors[2]) {
                rightGuest.layer.borderColor = accentColor.CGColor
            } else {
                rightGuest.layer.borderColor = UIColor.whiteColor().CGColor
            }
        }
        
        guestsView.applyShadow(2, opacity: 0.8, height: 2, shouldRasterize: false)
        guestsLabel.applyShadow(2, opacity: 0.8, height: 2, shouldRasterize: false)
    }




}
