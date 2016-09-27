//
//  HeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-15.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class HeaderView: UIView {
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var photosTag: UILabel!
    
    var timer:NSTimer?
    var storyItemIndex:Int = -1
    var story: [StoryItem]?
    
    var duration:Double = 8.0
    
    func loadImage(url:String) {
        self.photosTag.hidden = true
        image.loadImageUsingCacheWithURLString(url, completion: { result in
        
        })
    }
    
    func loadStory(story:[StoryItem]) {
        self.story = story
        if story.count != 0 {
            killTimer()
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "delay", userInfo: nil, repeats: false)
            
        }
    }
    
    func delay() {
        print("TIMER SET")
        timer?.invalidate()
        timer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: "nextStoryItem", userInfo: nil, repeats: true)
        nextStoryItem()
        self.photosTag.hidden = false
        self.photosTag.alpha = 0.0
        UIView.animateWithDuration(2.5, animations: {
            self.photosTag.alpha = 1.0
            
        })
    }
    
    func nextStoryItem() {
        
        let story = self.story!
        storyItemIndex += 1
//        print("nextStoryItem: \(storyItemIndex) of \(self.story!.count)")
        if storyItemIndex >= 0  &&  storyItemIndex < story.count {
            let item = story[storyItemIndex]
            if item.getContentType() == ContentType.Image {
                //loadImage((story[storyItemIndex].getDownloadUrl()?.absoluteString)!)
                loadTing((story[storyItemIndex].getDownloadUrl()?.absoluteString)!, completion: {
                    result in
                    
                })
            } else {
                nextStoryItem()
            }
        } else {
            storyItemIndex = -1
            nextStoryItem()
        }
    }
    
    func loadTing(_url:String, completion: (result: Bool)->()) {
        
        let url = NSURL(string: _url)
        NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler:
            { (data, response, error) in
                
                //error
                if error != nil {
                    print(error)
                    return
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    if let downloadedImage = UIImage(data: data!) {
                        imageCache.setObject(downloadedImage, forKey: _url)
                    }
                    
                    let newImage = UIImage(data: data!)
                    self.animateImages(newImage!)
                    completion(result: true)
                })
                
        }).resume()
    }
    
    func animateImages(image:UIImage)
    {
        
        UIView.transitionWithView(self.image,
                                  duration:2,
                                  options: .TransitionCrossDissolve,
                                  animations: { self.image.image = image },
                                  completion: { result in
                                    
        })
        
        self.image.transform = CGAffineTransformMakeScale(1.0, 1.0)
        //self.image.frame = CGRectMake(-50, 0, self.image.frame.width + 50, self.image.frame.height)
        UIView.animateWithDuration(duration, animations: {
            //self.image.frame = CGRectOffset(self.image.frame, 50, 0)
            self.image.transform = CGAffineTransformMakeScale(1.25, 1.25)
            
        })
    }
    
    func killTimer() {
        print("TIMER KILLED")
        storyItemIndex = -1
        timer?.invalidate()
        photosTag.hidden = true
        self.layer.removeAllAnimations()
        self.image.layer.removeAllAnimations()
        self.image.transform = CGAffineTransformMakeScale(1.0, 1.0)
    }
    
    func setTitle(str:String) {
        
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : UIFont(name: "Avenir-Black", size: 30.0)!,
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        
        let searchStrings = ["THE ", " THE ", " & "]
        for string in searchStrings {
            if let range = str.rangeOfString(string) {
                
                let index: Int = str.startIndex.distanceTo(range.startIndex) //will call successor/predecessor several times until the indices match
                let a2: [String: AnyObject] = [
                    
                    NSFontAttributeName : UIFont(name: "Avenir-Light", size: 30.0)!,
                    ]
                
                title.addAttributes(a2, range: NSRange(location: index, length: string.characters.count))
            }
        }
        
        self.titleLabel.attributedText = title //3
    }
    
    func setTitleSize(progress:CGFloat) {
        if progress < 0 {
            let scale = 1 + progress + 0.4
            
            let s = min(scale, 1.0)
            titleLabel.transform = CGAffineTransformMakeScale(s, s)
            image.alpha = 1 + progress
            photosTag.alpha = 0.8 + progress
        }
    }
}
