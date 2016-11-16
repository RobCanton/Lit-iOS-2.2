//
//  PostAuthorView.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-15.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class PostAuthorView: UIView {

    @IBOutlet weak var authorImageView: UIImageView!
    @IBOutlet weak var authorUsernameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    func setPostMetadata(post:StoryItem) {
        FirebaseService.getUser(post.getAuthorId(), completionHandler: { user in
            if user != nil {
                self.authorImageView.loadImageUsingCacheWithURLString(user!.getImageUrl(), completion: { result in })
                self.authorUsernameLabel.text = user!.getDisplayName()
            }
        })
        timeLabel.text = post.getDateCreated()!.timeStringSinceNow()
    }

}
