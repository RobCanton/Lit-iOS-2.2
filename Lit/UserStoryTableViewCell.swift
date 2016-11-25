//
//  UserStoryTableViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class UserStoryTableViewCell: UITableViewCell {

    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentImageView.layer.cornerRadius = 4
        contentImageView.clipsToBounds = true
        timeLabel.textColor = UIColor.grayColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setStory(story:Story) {
        let isLoaded = story.isLoaded()
        if isLoaded {
            usernameLabel.textColor = UIColor.whiteColor()
        } else {
            usernameLabel.textColor = UIColor.grayColor()
        }
        if let recentItem = story.getMostRecentItem() {
            contentImageView.image = nil
            contentImageView.loadImageUsingCacheWithURLString(recentItem.getDownloadUrl().absoluteString, completion: { loaded in
                if loaded {
                    if !isLoaded {
                        let image = self.contentImageView.image!.grayScaleImage()
                        self.contentImageView.image = image
                    }
                    UIView.animateWithDuration(0.3, animations: {
                        //self.fadeCover.alpha = 0.0
                    })
                }
            })
            
            FirebaseService.getUser(recentItem.getAuthorId(), completionHandler: { user in
                if user != nil {
                    self.usernameLabel.text = user!.getDisplayName()
                }
            })
            
            timeLabel.text = recentItem.getDateCreated()!.timeStringSinceNowWithAgo()
        }
    }
}
