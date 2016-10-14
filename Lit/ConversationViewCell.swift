//
//  ConversationViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-13.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

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
            
            let ref = FirebaseService.ref.child("conversations/\(conversation!.getKey())/messages")
            ref.queryLimitedToLast(1).observeEventType(.ChildAdded, withBlock: { snapshot in
                if snapshot.exists() {
                    let message = snapshot.value!["text"] as! String
                    let timeStamp = snapshot.value!["timestamp"] as! Double
                    self.timeLabel.text = NSDate(timeIntervalSince1970: timeStamp/1000).timeStringSinceNow()
                    self.messageLabel.text = message
                    
                }
            })
            
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
