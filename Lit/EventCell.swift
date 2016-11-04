//
//  EventCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-03.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class EventCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var eventImageView: UIImageView!
    
    @IBOutlet weak var gradientView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [UIColor.clearColor().CGColor, UIColor(white: 0.0, alpha: 1.0).CGColor]
        gradient.locations = [0.0 , 1.0]
        
        gradient.frame = gradientView.bounds
        gradientView.layer.insertSublayer(gradient, atIndex: 0)

    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setEvent(event:Event) {
        let date = event.getDate()
        dateLabel.text = getDateString(date)
        eventTitle.text = event.getName()
        
        dateLabel.applyShadow(2, opacity: 0.5, height: 2, shouldRasterize: false)
        eventTitle.applyShadow(2, opacity: 0.5, height: 2, shouldRasterize: false)

    }
    
}
