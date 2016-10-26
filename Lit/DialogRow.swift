//
//  DialogRow.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-26.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class DialogRow: UIButton {

    var isActive = true
    @IBOutlet weak var locationImageView: UIImageView!
    
    @IBOutlet weak var locationTitle: UILabel!

    @IBOutlet weak var selectionIndicator: UIImageView!
    @IBOutlet weak var divider: UIView!
    
    override func awakeFromNib() {
         super.awakeFromNib()
        
        
    }
    
    func setToProfileRow() {
        if let user = mainStore.state.userState.user {
            locationImageView.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in })
            locationImageView.layer.cornerRadius = locationImageView.frame.width/2
            locationImageView.clipsToBounds = true
            
            locationTitle.styleLocationTitle("my profile", size: 18.0)
            divider.hidden = false
        }
        
    }
    
    func setToLocationRow(location:Location) {
        locationImageView.loadImageUsingFileWithURLString(location, completion: { result in })
        locationImageView.layer.cornerRadius = 5
        locationImageView.clipsToBounds = true
    
        locationTitle.styleLocationTitle(location.getName().lowercaseString, size: 20.0)
    }
    
    func active(_isActive:Bool) {
        isActive = _isActive
        if isActive {
            self.locationTitle.alpha = 1.0
            self.locationImageView.alpha = 1.0
            self.selectionIndicator.alpha = 1.0
        } else {
            self.locationTitle.alpha = 0.4
            self.locationImageView.alpha = 0.4
            self.selectionIndicator.alpha = 0.0
        }
    }
}
