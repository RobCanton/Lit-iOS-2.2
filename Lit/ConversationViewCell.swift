//
//  ConversationViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-13.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class ConversationViewCell: UITableViewCell, GetUserProtocol {
    
    

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    
    var conversation:Conversation? {
        didSet{
            conversation!.delegate = self
            
            if let user = conversation!.getPartner() {
                userLoaded(user)
            }
            
            if let lastMessage = conversation!.lastMessage {
                messageLabel.text = lastMessage.text
                timeLabel.text = lastMessage.date.timeStringSinceNow()
            }
            
            if !conversation!.seen {
                userImageView.layer.borderColor = accentColor.CGColor
                userImageView.layer.borderWidth = 2.0
                messageLabel.font = UIFont(name: "Avenir-Heavy", size: 16.0)
                messageLabel.textColor = UIColor.whiteColor()
            } else {
                userImageView.layer.borderColor = UIColor.clearColor().CGColor
                userImageView.layer.borderWidth = 0
                messageLabel.font = UIFont(name: "Avenir-Medium", size: 16.0)
                messageLabel.textColor = UIColor(white: 0.7, alpha: 1.0)
            }
            
            
        }
    }
    
    
    func userLoaded(user: User) {
        userImageView.clipsToBounds = true
        userImageView.layer.cornerRadius = userImageView.frame.width/2
        userImageView.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: {result in})
        usernameLabel.text = user.getDisplayName()
    }
    
    
    override func awakeFromNib() {
       
    }
    
}
