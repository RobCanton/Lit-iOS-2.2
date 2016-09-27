//
//  LocationCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit


class LocationCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet private weak var imageCoverView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var speakerLabel: UILabel!
    
    var location: Location? {
        didSet {
            if let location = location {
                if let imageURL = location.getImageURL() {
                    self.imageView.loadImageUsingCacheWithURLString(imageURL) { (notFromCache) -> () in
                        // do stuff with the result
                        if notFromCache {
                            self.imageCoverView.alpha = 1.0
                            UIView.animateWithDuration(1.0, animations: {
                                self.imageCoverView.alpha = self.getImageCoverAlpha()
                            })
                        }
                        //self.titleLabel.text = location.getName().uppercaseString
                        //self.addressLabel.text = location.getAddress()
                        
                        self.titleLabel.styleLocationTitle(location.getName())
                        
                        let visitorsCount = location.getVisitors().count
                        let friendsCount = location.getFriendsCount()
                        
                        self.addressLabel.styleVisitorsCountLabel(visitorsCount, size: 22)
                        self.speakerLabel.styleFriendsCountLabel(friendsCount, size: 22)
                    }
                }
                
                if location.isActive {
                    self.layer.borderColor = accentColor.CGColor
                    self.layer.borderWidth = 0
                } else {
                    self.layer.borderColor = UIColor.clearColor().CGColor
                    self.layer.borderWidth = 0
                }
            }
        }
    }
    
    func getImageCoverAlpha () -> CGFloat{
        let featuredHeight = UltravisualLayoutConstants.Cell.featuredHeight
        let standardHeight = UltravisualLayoutConstants.Cell.standardHeight
        
        let delta = 1 - ((featuredHeight - CGRectGetHeight(frame)) / (featuredHeight - standardHeight))
        
        let minAlpha: CGFloat = 0.25
        let maxAlpha: CGFloat = 0.65
        
        return maxAlpha - (delta * (maxAlpha - minAlpha))
    }
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        super.applyLayoutAttributes(layoutAttributes)
        
        let featuredHeight = UltravisualLayoutConstants.Cell.featuredHeight
        let standardHeight = UltravisualLayoutConstants.Cell.standardHeight
        
        let delta = 1 - ((featuredHeight - CGRectGetHeight(frame)) / (featuredHeight - standardHeight))
        
        let scale = delta / 2
        titleLabel.transform = CGAffineTransformMakeScale(scale + 0.5, scale + 0.5)
        titleLabel.alpha = 0.7 + delta
        addressLabel.alpha = delta
        speakerLabel.alpha = delta
//        titleLabel.backgroundColor = UIColor(white: 0, alpha: delta - 0.5)
//        addressLabel.backgroundColor = UIColor(white: 0, alpha: delta - 0.5)
        
        imageCoverView.alpha = getImageCoverAlpha()
        
    }
    
    func offset(offset: CGPoint) {
        //imageView.clipsToBounds = false
        imageView.frame = CGRectOffset(self.imageView.bounds, offset.x, offset.y)
    }
    
}
