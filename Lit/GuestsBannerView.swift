//
//  GuestsBannerView.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-23.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class GuestsBannerView: UIView {
    
    @IBOutlet weak var mainView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func setGuests() {
        
        let numGuests = 3
        
        for i in 1 ... numGuests {
            let image = UIImage(named: "11")
            let profileView = UIImageView(image: image)
            profileView.frame = CGRectMake(0, 0, 40, 40)
            profileView.layer.cornerRadius = profileView.frame.width/2
            profileView.clipsToBounds = true
            let x = (CGFloat(i) * (profileView.frame.width * (0.75 - (0.02 * CGFloat(i)))))
            profileView.center = CGPointMake(x, mainView.center.y/2)
            mainView.addSubview(profileView)
            mainView.sendSubviewToBack(profileView)
        }
    }
}
