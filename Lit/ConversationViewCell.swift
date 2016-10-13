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
    
    
    var conversation:Conversation? {
        didSet{
            conversation!.delegate = self
            
            if let user = conversation!.getPartner() {
                userLoaded(user)
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
