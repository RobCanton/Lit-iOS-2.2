//
//  PhotoCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-05.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {


    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var authorImage: UIImageView!
    
    @IBOutlet weak var authorUsername: UILabel!

    @IBOutlet weak var gradientView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
//        let gradient: CAGradientLayer = CAGradientLayer()
//        
//        gradient.colors = [UIColor.clearColor().CGColor, UIColor(white: 0.0, alpha: 0.5).CGColor]
//        gradient.locations = [0.0 , 1.0]
//        
//        gradient.frame = gradientView.bounds
//        gradientView.layer.insertSublayer(gradient, atIndex: 0)
        
        authorImage.layer.cornerRadius = authorImage.frame.width/2
        authorImage.clipsToBounds = true
        authorImage.layer.borderColor = UIColor.whiteColor().CGColor
        authorImage.layer.borderWidth = 0.5
        
    }
    
    func setPhoto(item:StoryItem) {
        imageView.image = nil
        imageView.loadImageUsingCacheWithURLString(item.getDownloadUrl()!.absoluteString, completion: { loaded in
            if loaded {

                UIView.animateWithDuration(0.3, animations: {
                    //self.fadeCover.alpha = 0.0
                    
                    
                })
            }

        })
        
        FirebaseService.getUser(item.getAuthorId(), completionHandler: { user in
            if user != nil {
                self.authorImage.loadImageUsingCacheWithURLString(user!.getImageUrl(), completion: { result in })
                self.authorUsername.text = user!.getDisplayName()
            }
        })
        
        
        self.layer.borderColor = UIColor.blackColor().CGColor
        self.layer.borderWidth = 1.0
        
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
        
    }
    
    
    
    
    

}
