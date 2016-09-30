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
    
    @IBOutlet weak var postsCountLabel: UILabel!
    var location: Location? {
        didSet {
            if let location = location {
                imageView.image = nil
                if let imageURL = location.getImageURL() {
                    loadLocationImage(imageURL, completion: { (notFromCache) in })
                }
                
                self.titleLabel.styleLocationTitle(location.getName(), size: 32.0)
                
                location.collectInfo()
                let visitorsCount = location.getVisitorsCount()
                let friendsCount = location.getFriendsCount()
                
                self.addressLabel.styleVisitorsCountLabel(visitorsCount, size: 20)
                self.speakerLabel.styleFriendsCountLabel(friendsCount, size: 20, you: location.getKey() == mainStore.state.userState.activeLocationKey)
                
                
                postsCountLabel.text = "\(location.getPostKeys().count)"
            }
        }
    }
    
    func getImageCoverAlpha () -> CGFloat{
        let featuredHeight = UltravisualLayoutConstants.Cell.featuredHeight
        let standardHeight = UltravisualLayoutConstants.Cell.standardHeight
        
        let delta = 1 - ((featuredHeight - CGRectGetHeight(frame)) / (featuredHeight - standardHeight))
        
        let minAlpha: CGFloat = 0
        let maxAlpha: CGFloat = 0.75
        
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
        
        if delta > 0 {
            titleLabel.layer.masksToBounds = false
            titleLabel.layer.shadowOffset = CGSize(width: 0, height: 4)
            titleLabel.layer.shadowOpacity = 0.8
            titleLabel.layer.shadowRadius = 4
        } else {
            titleLabel.layer.masksToBounds = true
            titleLabel.layer.shadowOpacity = 0
            titleLabel.layer.shadowRadius = 0
        }
        
    }
    
    func offset(offset: CGPoint) {
        //imageView.clipsToBounds = false
        imageView.frame = CGRectOffset(self.imageView.bounds, offset.x, offset.y)
    }
    
    var task:NSURLSessionDataTask?
    func loadLocationImage(_url:String, completion: (result: Bool)->()) {
        if task != nil{
            
            task!.cancel()
            task = nil
            
        }
        
        // Check for cached image
        if let cachedImage = imageCache.objectForKey(_url) as? UIImage {
            imageView.image = cachedImage
            return completion(result: false)
        }
        
        // Otherwise, download image
        let url = NSURL(string: _url)
        
        
        task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler:
            { (data, response, error) in
                
                //error
                if error != nil {
                    if error?.code == -999 {
                        return
                    }
                    print(error?.code)
                    return
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    if let downloadedImage = UIImage(data: data!) {
                        imageCache.setObject(downloadedImage, forKey: _url)
                    }
                    
                    self.imageView.image = UIImage(data: data!)
                    completion(result: true)
                })
                
        })
        
        task?.resume()
        
    }
    
}
