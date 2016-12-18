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
    
    func setStory(story:Story) {
        self.separatorInset = UIEdgeInsets(top: 0, left: self.bounds.size.width/2, bottom: 0, right: self.bounds.size.width/2)

        guard let item = story.getMostRecentItem() else { return }
        let state = story.state
        contentImageView.image = nil
        contentImageView.loadImageUsingCacheWithURLString(item.getDownloadUrl().absoluteString, completion: { loaded in
            if loaded {
//                if state == .NotLoaded || state == .Loading {
//                    let image = self.contentImageView.image!.grayScaleImage()
//                    self.contentImageView.image = image
//                }

                UIView.animateWithDuration(0.3, animations: {
                    //self.fadeCover.alpha = 0.0
                })
            }
        })
            
        if state == .Loaded {
            usernameLabel.textColor = UIColor.whiteColor()
            timeLabel.text = "\(item.getDateCreated()!.timeStringSinceNowWithAgo())"
        } else if state == .Loading {
            usernameLabel.textColor = UIColor.grayColor()
            timeLabel.text = "Loading..."
        } else if state == .NotLoaded {
            usernameLabel.textColor = UIColor.grayColor()
            timeLabel.text = "\(item.getDateCreated()!.timeStringSinceNowWithAgo())"
        }
    }
}
