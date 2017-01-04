//
//  DialogRow.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-26.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class DialogRow: UIButton {

    var key:String!
    var isActive = true
    @IBOutlet weak var locationImageView: UIImageView!
    
    @IBOutlet weak var locationTitle: UILabel!

    @IBOutlet weak var selectionIndicator: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 4
        self.clipsToBounds = true
        active(false)
    }
    
    func setToProfileRow() {
        key = "profile"
        if let user = mainStore.state.userState.user {
            locationImageView.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in })
            locationImageView.layer.cornerRadius = locationImageView.frame.width/2
            locationImageView.clipsToBounds = true
            locationTitle.text = "My Profile"
        }
        
    }
    
    func setToLocationRow(location:Location) {
        key = location.getKey()
        locationImageView.loadImageUsingFileWithURLString(location, completion: { result in })
        locationImageView.layer.cornerRadius = 5
        locationImageView.clipsToBounds = true
        locationTitle.text = location.getName()
    }
    
    func active(_isActive:Bool) {
        isActive = _isActive
        if isActive {
//            self.locationTitle.alpha = 1.0
//            self.locationImageView.alpha = 1.0
            self.selectionIndicator.alpha = 1.0
            backgroundColor = UIColor(white: 0.15, alpha: 1.0)
            
        } else {
//            self.locationTitle.alpha = 0.75
//            self.locationImageView.alpha = 0.75
            self.selectionIndicator.alpha = 0.0
            backgroundColor = UIColor(white: 0.0, alpha: 1.0)
        }
    }
}
