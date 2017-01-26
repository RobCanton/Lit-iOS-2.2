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
    
    @IBOutlet weak var unread_dot: UIImageView!
    
    
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
                usernameLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 16.0)
                unread_dot.hidden = false
            } else {

                usernameLabel.font = UIFont(name: "AvenirNext-Regular", size: 16.0)
                unread_dot.hidden = true
            }
            
            
        }
    }
    
    
    func userLoaded(user: User) {
        userImageView.clipsToBounds = true
        userImageView.layer.cornerRadius = userImageView.frame.width/2
        userImageView.contentMode = .ScaleAspectFill
        userImageView.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: {result in})
        usernameLabel.text = user.getDisplayName()
    }
    
    
    override func awakeFromNib() {
       
    }
    
}
