//
//  InfoTableViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

enum InfoType {
    case FullAddress, Phone, Email, Website, None
}

class InfoTableViewCell: UITableViewCell {

    var type:InfoType = .None
    
    @IBOutlet weak var label: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
