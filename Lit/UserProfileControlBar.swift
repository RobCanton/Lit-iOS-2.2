//
//  UserProfileControlBar.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class UserProfileControlBar: UIView {

    @IBOutlet weak var leftBlock: UIView!
    @IBOutlet weak var centerBlock: UIView!
    @IBOutlet weak var rightBlock: UIView!

    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var centerLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    
    func setControlBar() {
        leftLabel.styleProfileBlockText(130, text: "Reputation", color: UIColor.whiteColor())
        centerLabel.styleProfileBlockText(12, text: "Posts", color: UIColor.whiteColor())
        rightLabel.styleProfileBlockText(6, text: "Friends", color: UIColor.whiteColor())
        
        self.layer.borderWidth = 1.5
        self.layer.borderColor = UIColor.blackColor().CGColor

    }
}
