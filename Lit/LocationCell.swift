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
    
    @IBOutlet weak var guestsLabel: UILabel!
    @IBOutlet weak var guestsView: UIView!
    
    @IBOutlet weak var postsCountLabel: UILabel!
    
    var leftGuest:UIImageView!
    var centerGuest:UIImageView!
    var rightGuest:UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        let size = guestsView.frame.height
        
        centerGuest = UIImageView()
        centerGuest.backgroundColor = UIColor.blackColor()
        centerGuest.frame = CGRectMake(0, 0, size * 1.05, size * 1.05)
        centerGuest.layer.cornerRadius = centerGuest.frame.width/2
        centerGuest.clipsToBounds = true
        
        leftGuest = UIImageView()
        leftGuest.backgroundColor = UIColor.blackColor()
        leftGuest.frame = CGRectMake(0, 0, size, size)
        leftGuest.layer.cornerRadius = leftGuest.frame.width/2
        leftGuest.clipsToBounds = true
        
        rightGuest = UIImageView()
        rightGuest.backgroundColor = UIColor.blackColor()
        rightGuest.frame = CGRectMake(0, 0, size, size)
        rightGuest.layer.cornerRadius = rightGuest.frame.width/2
        rightGuest.clipsToBounds = true
        
        centerGuest.layer.borderColor = UIColor.whiteColor().CGColor
        centerGuest.layer.borderWidth = 1
        leftGuest.layer.borderColor = UIColor.whiteColor().CGColor
        leftGuest.layer.borderWidth = 1
        rightGuest.layer.borderColor = UIColor.whiteColor().CGColor
        rightGuest.layer.borderWidth = 1
   
        guestsView.addSubview(leftGuest)
        guestsView.addSubview(rightGuest)
        guestsView.addSubview(centerGuest)
    }
    
    
    var location: Location? {
        didSet {
            if let location = location {
                imageView.image = nil
                loadLocationImage(location.getImageURL() , completion: { (notFromCache) in})
                
                self.titleLabel.styleLocationTitle(location.getName(), size: 32.0)
                
                location.collectInfo()
                let visitorsCount = location.getVisitorsCount()
                let friendsCount = location.getFriendsCount()
                
                self.addressLabel.styleVisitorsCountLabel(visitorsCount, size: 20)
                self.speakerLabel.styleFriendsCountLabel(friendsCount, size: 20, you: location.getKey() == mainStore.state.userState.activeLocationKey)
                
                postsCountLabel.text = "\(location.getPostKeys().count)"
                
                setGuests()
            }
        }
    }
    
    func setGuests() {

        let size = guestsView.frame.height
        let visitors = location!.getVisitors()
        let count = visitors.count
        if count == 1 {
            guestsLabel.text = "1 guest"
        } else if count > 1{
            guestsLabel.text = "\(count) guests"
        } else {
            guestsLabel.text = ""
        }
        
        centerGuest.hidden = true
        leftGuest.hidden = true
        rightGuest.hidden = true
        centerGuest.center = CGPointMake(self.frame.width/2 - size/4, guestsView.bounds.height/2)
        
        if visitors.count == 1 {
            FirebaseService.getUser(visitors[0], completionHandler: { _user in
                if let user = _user {
                    self.centerGuest.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in })
                }
            })
            centerGuest.hidden = false
            if isFriend(visitors[0]) {
                centerGuest.layer.borderColor = accentColor.CGColor
            } else {
                centerGuest.layer.borderColor = UIColor.whiteColor().CGColor
            }
        }
        if visitors.count == 2 {
            FirebaseService.getUser(visitors[0], completionHandler: { _user in
                if let user = _user {
                    self.leftGuest.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in })
                }
            })
            FirebaseService.getUser(visitors[1], completionHandler: { _user in
                if let user = _user {
                    self.rightGuest.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in })
                }
            })
            leftGuest.hidden = false
            rightGuest.hidden = false
            
            leftGuest.center = CGPointMake(centerGuest.center.x - size * 0.55, guestsView.bounds.height/2)
            rightGuest.center = CGPointMake(centerGuest.center.x + size * 0.55, guestsView.bounds.height/2)
            
            if isFriend(visitors[0]) {
                leftGuest.layer.borderColor = accentColor.CGColor
            } else {
                leftGuest.layer.borderColor = UIColor.whiteColor().CGColor
            }
            if isFriend(visitors[1]) {
                rightGuest.layer.borderColor = accentColor.CGColor
            } else {
                rightGuest.layer.borderColor = UIColor.whiteColor().CGColor
            }
            
        }
        
        if visitors.count >= 3 {
            FirebaseService.getUser(visitors[0], completionHandler: { _user in
                if let user = _user {
                    self.centerGuest.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in })
                }
            })
            FirebaseService.getUser(visitors[1], completionHandler: { _user in
                if let user = _user {
                    self.leftGuest.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in })
                }
            })
            FirebaseService.getUser(visitors[2], completionHandler: { _user in
                if let user = _user {
                    self.rightGuest.loadImageUsingCacheWithURLString(user.getImageUrl(), completion: { result in })
                }
            })
            centerGuest.hidden = false
            leftGuest.hidden = false
            rightGuest.hidden = false

            leftGuest.center = CGPointMake(centerGuest.center.x - size * 0.85, guestsView.bounds.height/2)
            rightGuest.center = CGPointMake(centerGuest.center.x + size * 0.85, guestsView.bounds.height/2)
            
            if isFriend(visitors[0]) {
                centerGuest.layer.borderColor = accentColor.CGColor
            } else {
                centerGuest.layer.borderColor = UIColor.whiteColor().CGColor
            }
            
            if isFriend(visitors[1]) {
                leftGuest.layer.borderColor = accentColor.CGColor
            } else {
                leftGuest.layer.borderColor = UIColor.whiteColor().CGColor
            }
            if isFriend(visitors[2]) {
                rightGuest.layer.borderColor = accentColor.CGColor
            } else {
                rightGuest.layer.borderColor = UIColor.whiteColor().CGColor
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
        guestsView.alpha = delta
        
        imageCoverView.alpha = getImageCoverAlpha()
        
        if delta > 0 {
            titleLabel.applyShadow(2, opacity: 0.8, height: 2, shouldRasterize: false)
            guestsView.applyShadow(2, opacity: 0.8, height: 2, shouldRasterize: false)
            guestsLabel.applyShadow(2, opacity: 0.8, height: 2, shouldRasterize: false)
        } else {
            titleLabel.applyShadow(0, opacity: 0, height: 0, shouldRasterize: false)
            guestsView.applyShadow(0, opacity: 0, height: 0, shouldRasterize: false)
            guestsLabel.applyShadow(0, opacity: 0, height: 0, shouldRasterize: false)
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
        
        if let file = location!.imageOnDiskURL {
            self.imageView.image = UIImage(contentsOfFile: file.path!)
            completion(result: false)
        } else {
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
                    
                    let  documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
                    if let image = UIImage(data: data!) {
                        let fileURL = documentsURL.URLByAppendingPathComponent("\(self.location!.getKey()).jpg")
                        if let jpgData = UIImageJPEGRepresentation(image, 1.0) {
                            jpgData.writeToURL(fileURL, atomically: false)
                            self.location!.imageOnDiskURL = fileURL
                        
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.imageView.image = UIImage(data: data!)
                        completion(result: true)
                    })
                    
            })
            
            task?.resume()
        }
    }
    
}
