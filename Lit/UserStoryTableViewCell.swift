//
//  UserStoryTableViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class UserStoryTableViewCell: UITableViewCell, StoryProtocol {


    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var userStory:UserStory?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageContainer.layer.cornerRadius = imageContainer.frame.width/2
        imageContainer.clipsToBounds = true
        imageContainer.layer.borderColor = UIColor.blackColor().CGColor
        imageContainer.layer.borderWidth = 1.8
        
        contentImageView.layer.cornerRadius = contentImageView.frame.width/2
        contentImageView.clipsToBounds = true
        
        timeLabel.textColor = UIColor.grayColor()
    }
    
    func activate(animated:Bool) {
        if animated {
            let color:CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
            color.fromValue = UIColor.blackColor().CGColor
            color.toValue = accentColor.CGColor
            imageContainer.layer.borderColor = accentColor.CGColor
            
            
            let both:CAAnimationGroup = CAAnimationGroup()
            both.duration = 0.30
            both.animations = [color]
            both.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            
            imageContainer.layer.addAnimation(both, forKey: "color and Width")
        } else {
            imageContainer.layer.borderColor = accentColor.CGColor
        }
    }
    
    func deactivate() {
        imageContainer.layer.borderColor = UIColor.blackColor().CGColor
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func setUserStory(story:UserStory) {
        self.userStory = story
        story.delegate = self
        stateChange(story.state)
        
        FirebaseService.getUser(story.getUserId(), completionHandler: { user in
            if user != nil {
                if user!.getUserId() == mainStore.state.userState.uid {
                    self.usernameLabel.text = "My Activity"
                } else {
                    self.usernameLabel.text = user!.getDisplayName()
                }
                
                
                // Load in image to avoid blip in story view
                loadImageUsingCacheWithURL(user!.getImageUrl(), completion: { image, fromCache in})
            }
        })
    }
    
    
    func stateChange(state:UserStoryState) {
        print("STATE CHANGE: \(state)")
        switch state {
        case .NotLoaded:
            userStory?.downloadItems()
            self.usernameLabel.textColor = UIColor.grayColor()
            break
        case .LoadingItemInfo:
            self.usernameLabel.textColor = UIColor.grayColor()
            break
        case .ItemInfoLoaded:
            self.usernameLabel.textColor = UIColor.grayColor()
            itemsLoaded()
            break
        case .LoadingContent:
            self.usernameLabel.textColor = UIColor.grayColor()
            loadingContent()
            break
        case .ContentLoaded:
            self.usernameLabel.textColor = UIColor.whiteColor()
            contentLoaded()
            break
        }
    }
    
    func itemsLoaded() {
        guard let items = userStory?.items else { return }
        if items.count > 0 {
            let lastItem = items[items.count - 1]
            self.timeLabel.text = "\(lastItem.getDateCreated()!.timeStringSinceNowWithAgo())"
            activate(false)
            loadImageUsingCacheWithURL(lastItem.getDownloadUrl().absoluteString, completion: { image, fromCache in
                
                if !fromCache {
                    self.contentImageView.alpha = 0.0
                    UIView.animateWithDuration(0.30, animations: {
                        self.contentImageView.alpha = 1.0
                    })
                } else {
                    self.contentImageView.alpha = 1.0
                }
                self.contentImageView.image = image
            })
        }
    }
    
    func loadingContent() {
        timeLabel.text = "Loading..."
    }
    
    func contentLoaded() {
        guard let items = userStory?.items else { return }
        if items.count > 0 {
            let lastItem = items[items.count - 1]
            timeLabel.text = "\(lastItem.getDateCreated()!.timeStringSinceNowWithAgo())"
        }
    }
}
