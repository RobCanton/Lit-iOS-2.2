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
    
    
//    @IBOutlet weak var gradientView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderColor = UIColor.blackColor().CGColor
        self.layer.borderWidth = 1.0

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
    }
    

    
    
    
    

}
