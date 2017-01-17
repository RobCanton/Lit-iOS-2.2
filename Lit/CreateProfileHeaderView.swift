//
//  CreateProfileHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-06.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import Firebase


class CreateProfileHeaderView: UIView {

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var errorLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        
        
    }
    
    
    func animateDown() {
        UIView.animateWithDuration(0.5, animations: {
            self.imageView.alpha = 0.6
        })
    }
    
    func animateUp() {
        UIView.animateWithDuration(0.15, animations: {
            self.imageView.alpha = 1.0
        })
    }
}
