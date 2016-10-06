//
//  PhotoCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-05.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {

    @IBOutlet weak var authorImage: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var timeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setPhoto(item:StoryItem) {
        imageView.loadImageUsingCacheWithURLString(item.getDownloadUrl()!.absoluteString, completion: {_ in 
        
        })
        
        self.layer.borderColor = UIColor.blackColor().CGColor
        self.layer.borderWidth = 1.5
        
        //timeLabel.text = item.getDateCreated()!.timeStringSinceNow()
        authorImage.layer.cornerRadius = authorImage.frame.width/2
        authorImage.clipsToBounds = true
        
        FirebaseService.getUser(item.getAuthorId(), completionHandler: { _user in
            if let user = _user {
                self.authorImage.loadImageUsingCacheWithURLString(user.getImageUrl()!, completion: {
                    result in
                })
            }
        })
    }

}
