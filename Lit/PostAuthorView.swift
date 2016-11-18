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
    
    var user:User?
    var authorTap:UITapGestureRecognizer!
    var authorTappedHandler:((user:User)->())?
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        super.awakeFromNib()
        authorImageView.layer.cornerRadius = authorImageView.frame.width/2
        authorImageView.clipsToBounds = true
        authorTap = UITapGestureRecognizer(target: self, action: #selector(authorTapped))
    }
    
    func setPostMetadata(post:StoryItem) {
        FirebaseService.getUser(post.getAuthorId(), completionHandler: { user in
            if user != nil {
                self.authorImageView.loadImageUsingCacheWithURLString(user!.getImageUrl(), completion: { result in })
                self.authorUsernameLabel.text = user!.getDisplayName()
                self.authorImageView.userInteractionEnabled = true
                self.authorImageView.removeGestureRecognizer(self.authorTap)
                self.authorImageView.addGestureRecognizer(self.authorTap)
                self.user = user
            }
        })
        timeLabel.text = post.getDateCreated()!.timeStringSinceNow()
    }
    
    func authorTapped(gesture:UITapGestureRecognizer) {
        if user != nil {
            authorTappedHandler?(user: user!)
        }
    }

}
