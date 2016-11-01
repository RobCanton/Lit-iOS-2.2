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

    }
    
    @IBAction func phoneLink(sender: AnyObject) {

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
