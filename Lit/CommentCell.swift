//
//  CommentCell.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-26.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {

    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    var authorTapped:((userId:String)->())?
    
    var comment:Comment!
    @IBOutlet weak var userImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundView = nil
        backgroundColor = UIColor.clearColor()
        selectedBackgroundView = nil

        tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        userImage.addGestureRecognizer(tap)
        
        userImage.userInteractionEnabled = true
    }
    
    var tap:UITapGestureRecognizer!

    func handleTap(sender:UITapGestureRecognizer) {
        authorTapped?(userId: comment.getAuthor())
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func setContent(comment:Comment) {
        self.comment = comment
        userImage.layer.cornerRadius = userImage.frame.width / 2
        userImage.clipsToBounds = true
        
        commentLabel.text = comment.getText()
        backgroundColor = UIColor.clearColor()
        backgroundView = nil
        
        FirebaseService.getUser(comment.getAuthor(), completionHandler: { user in
            if user != nil {
                self.authorLabel.text = user!.getDisplayName()
                loadImageUsingCacheWithURL(user!.getImageUrl(), completion: { image, fromCache in
                    self.userImage.image = image
                })
            }
        })
    }
    
}
