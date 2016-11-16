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
    @IBOutlet weak var authorLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var fadeCover: UIView!
    
    @IBOutlet weak var likeTag: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.likeTag.hidden = true
    }
    
    func setPhoto(item:StoryItem) {
        imageView.image = nil
        imageView.loadImageUsingCacheWithURLString(item.getDownloadUrl()!.absoluteString, completion: { loaded in
            if loaded {

                UIView.animateWithDuration(0.3, animations: {
                    self.fadeCover.alpha = 0.0
                })
            }

        })
        
        
        self.layer.borderColor = UIColor.blackColor().CGColor
        self.layer.borderWidth = 1.0
        
        likeTag.layer.cornerRadius = likeTag.frame.width/2
        likeTag.clipsToBounds = true
        
        
//        let userLikedRef = FirebaseService.ref.child("uploads/\(item.getKey())/likes/\(mainStore.state.userState.uid)")
//        userLikedRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
//            if snapshot.exists() {
//                let liked = snapshot.value! as! Bool
//                if liked {
//                    self.likeTag.hidden = false
//                } else {
//                    self.likeTag.hidden = true
//                }
//            } else {
//                self.likeTag.hidden = true
//            }
//        })
    }
    
    func setTitle(titleStr:String) {
        titleLabel.text = titleStr
    }
    
    
    

}
