//
//  GuestsBannerView.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-23.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

protocol LocationDetailsProtocol {
    func showMap()
}

class LocationDetailsView: UIView {
    
    @IBOutlet weak var addressLabel: UILabel!

    
    @IBOutlet weak var addresView: UIView!
    var location:Location!
    var delegate: LocationDetailsProtocol?
    var addressTap:UITapGestureRecognizer!
    @IBAction func websiteLink(sender: AnyObject) {
        let url = NSURL(string: location.getWebsite())!
        if UIApplication.sharedApplication().canOpenURL(url) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    @IBAction func phoneLink(sender: AnyObject) {
        let prompt = "telprompt://\(location.getNumber())";
        let fallBack = "tel://\(location.getNumber())";
        let promptURL:NSURL = NSURL(string:prompt)!;
        let fallBackURL:NSURL = NSURL(string:fallBack)!;
        
        if UIApplication.sharedApplication().canOpenURL(promptURL) {
            UIApplication.sharedApplication().openURL(promptURL)
        } else if UIApplication.sharedApplication().canOpenURL(fallBackURL) {
            UIApplication.sharedApplication().openURL(fallBackURL)
        } else {
            //
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func setLocation(location:Location) {
        self.location = location
        addressLabel.text = location.getAddress()

        addressTap = UITapGestureRecognizer(target: self, action: #selector(showMap))
        addresView.userInteractionEnabled = true
        addresView.addGestureRecognizer(addressTap)
    }
    
    func showMap(gesture:UITapGestureRecognizer) {
        delegate?.showMap()
    }
}
