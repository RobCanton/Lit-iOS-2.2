//
//  UserStoryTableViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class MyStoryTableViewCell: UITableViewCell {

    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentImageView.layer.cornerRadius = 4
        contentImageView.clipsToBounds = true
        timeLabel.textColor = UIColor.grayColor()
        self.layoutMargins = UIEdgeInsetsZero
        self.separatorInset = UIEdgeInsets(top: 0, left: self.bounds.size.width/2, bottom: 0, right: self.bounds.size.width/2)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
