//
//  Extensions.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-28.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import RecordButton

let imageCache = NSCache()

extension UIImageView {
    
    func loadImageUsingCacheWithURLString(_url:String, completion: (result: Bool)->()) {
        
        // Check for cached image
        if let cachedImage = imageCache.objectForKey(_url) as? UIImage {
            self.image = cachedImage
            return completion(result: false)
        }
        
        // Otherwise, download image
        let url = NSURL(string: _url)

        let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler:
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
                    
                    self.image = UIImage(data: data!)
                    completion(result: true)
                })
                
        }).resume()
        
    }
    
    func loadImageUsingFileWithURLString(location:Location, completion: (result: Bool)->()) {
        
        if let file = location.imageOnDiskURL {
            print("loaded \(location.getKey()) from file")
            self.image = UIImage(contentsOfFile: file.path!)
            completion(result: false)
        } else {
            // Otherwise, download image
            let url = NSURL(string: location.getImageURL())
            
            NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler:
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
                        let fileURL = documentsURL.URLByAppendingPathComponent("\(location.getKey()).jpg")
                        if let jpgData = UIImageJPEGRepresentation(image, 1.0) {
                            jpgData.writeToURL(fileURL, atomically: false)
                            location.imageOnDiskURL = fileURL
                            
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        print("downloaded \(location.getKey())")
                        self.image = UIImage(data: data!)
                        completion(result: true)
                    })
                    
            }).resume()
        }
        
    }
    
}

extension UIImage {
    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
        let radiansToDegrees: (CGFloat) -> CGFloat = {
            return $0 * (180.0 / CGFloat(M_PI))
        }
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(M_PI)
        }
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: size))
        let t = CGAffineTransformMakeRotation(degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0);
        
        //   // Rotate the image context
        CGContextRotateCTM(bitmap, degreesToRadians(degrees));
        
        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat
        
        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }
        
        CGContextScaleCTM(bitmap, yFlip, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), CGImage)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
}

extension NSDate
{
    
    func timeStringSinceNow() -> String
    {
        let calendar = NSCalendar.currentCalendar()
        
        let components = calendar.components([.Day, .Hour, .Minute, .Second], fromDate: self, toDate: NSDate(), options: [])
        
        if components.day > 0 {
            return "\(components.day)d ago"
        }
        else if components.hour > 0 {
            return "\(components.hour)h ago"
        }
        else if components.minute > 0 {
            return "\(components.minute)m ago"
        }
        
        return "\(components.second)s ago"
    }

}

extension UILabel
{
    func styleLocationTitle(_str:String, size: CGFloat) {
        let str = _str.lowercaseString
        let font = UIFont(name: "Avenir-Black", size: size)
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : font!,
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        
        let searchStrings = ["the ", " the ", " & ", "nightclub", " nightclub ", "club", " club", "you are near"]
        for string in searchStrings {
            if let range = str.rangeOfString(string) {
                
                let index: Int = str.startIndex.distanceTo(range.startIndex)
                
                let a2: [String: AnyObject] = [
                    NSFontAttributeName : UIFont(name: "Avenir-Light", size: size)!,
                ]
                
                title.addAttributes(a2, range: NSRange(location: index, length: string.characters.count))
            }
        }
        
        self.attributedText = title
    }
    
    func styleLocationTitleWithPreText(str:String, size1: CGFloat, size2: CGFloat) {
        let font = UIFont(name: "Avenir-Black", size: size1)
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : font!,
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        
        let preStrings = ["you are at", "uploading to"]
        for string in preStrings {
            if let range = str.rangeOfString(string) {
                let index = str.startIndex.distanceTo(range.startIndex)
                let a: [String: AnyObject] = [
                    NSFontAttributeName : UIFont(name: "Avenir-Light", size: size2)!,
                    NSForegroundColorAttributeName : UIColor.whiteColor()
                ]
                title.addAttributes(a, range: NSRange(location: index, length: string.characters.count))
            }
        }
        
        let searchStrings = ["the ", " the ", " & ", "nightclub", " nightclub ", "club", " club"]
        for string in searchStrings {
            if let range = str.rangeOfString(string) {
                
                let index: Int = str.startIndex.distanceTo(range.startIndex)
                
                let a2: [String: AnyObject] = [
                    NSFontAttributeName : UIFont(name: "Avenir-Light", size: size1)!,
                    ]
                
                title.addAttributes(a2, range: NSRange(location: index, length: string.characters.count))
            }
        }
        
        self.attributedText = title //3
    }
    
    func styleVisitorsCountLabel(count:Int, size: CGFloat) {
        
        var str = ""
        
        if count == 1 {
            str = "\(count) person is here"
        } else if count > 1 {
            str = "\(count) people are here"
        }
        
        let font = UIFont(name: "Avenir-Book", size: size)
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : font!,
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        
        let countStr = "\(count)"
        if let range = str.rangeOfString(countStr) {
            let index = str.startIndex.distanceTo(range.startIndex)
            let a: [String: AnyObject] = [
                NSFontAttributeName : UIFont(name: "Avenir-Black", size: size)!,
                NSForegroundColorAttributeName : UIColor.whiteColor()
            ]
            title.addAttributes(a, range: NSRange(location: index, length: countStr.characters.count))
        }

        
        self.attributedText = title
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowOpacity = 0.8
        self.layer.shadowRadius = 4
        self.layer.shouldRasterize = true
    }
    
    func styleFriendsCountLabel(count:Int, size: CGFloat, you:Bool) {
        
        var str = ""
        
        if count == 0 && you {
            str = "you are here"
        } else if count == 1 && !you {
            str = "\(1) of your friends is here"
        } else if count == 1 && you{
            str = "you and a friend are here"
        } else if count > 1 && !you {
            str = "\(count) of your friends are here"
        } else if count > 1 && you {
            str = "you and \(count) friends are here"
        }
        
        let font = UIFont(name: "Avenir-Book", size: size)
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : font!,
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        
        let searchStrings = ["\(count)", "you ", "friend", "friends"]
        for string in searchStrings {
            if let range = str.rangeOfString(string) {
                
                let index: Int = str.startIndex.distanceTo(range.startIndex)
                
                let a: [String: AnyObject] = [
                    NSFontAttributeName : UIFont(name: "Avenir-Black", size: size )!,
                    NSForegroundColorAttributeName : UIColor.whiteColor()
                ]
                
                title.addAttributes(a, range: NSRange(location: index, length: string.characters.count))
            }
        }
        
        
        self.attributedText = title
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowOpacity = 0.8
        self.layer.shadowRadius = 4
        self.layer.shouldRasterize = true
    }
    
    
    func styleProfileBlockText(count:Int, text:String, size1: CGFloat, size2: CGFloat) {
        self.numberOfLines = 2
        self.textAlignment = .Center
        let str = "\(count)\n\(text)"
        let font = UIFont(name: "Avenir-Book", size: 12)
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : font!,
            NSForegroundColorAttributeName : UIColor(white: 0, alpha: 0.7)
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        
        let countStr = "\(count)"
        if let range = str.rangeOfString(countStr) {
            let index = str.startIndex.distanceTo(range.startIndex)
            let a: [String: AnyObject] = [
                NSFontAttributeName : UIFont(name: "Avenir-Black", size: 20)!,
                NSForegroundColorAttributeName : UIColor.blackColor()
            ]
            title.addAttributes(a, range: NSRange(location: index, length: countStr.characters.count))
        }
        
        
        self.attributedText = title
    }
}

public extension UISearchBar {
    
    public func setTextColor(color: UIColor) {
        let svs = subviews.flatMap { $0.subviews }
        guard let tf = (svs.filter { $0 is UITextField }).first as? UITextField else { return }
        tf.textColor = color
    }
}

public extension String {
    func containsIgnoringCase(find: String) -> Bool{
        return self.rangeOfString(find, options: NSStringCompareOptions.CaseInsensitiveSearch) != nil
    }
}

public extension UIView {
    func applyShadow(radius:CGFloat, opacity:Float, height:CGFloat, shouldRasterize:Bool) {
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize(width: 0, height: height)
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = radius
        self.layer.shouldRasterize = shouldRasterize
    }
    
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.3
        animation.values = [-5.0, 5.0, -2.0, 2.0, 0.0 ]
        layer.addAnimation(animation, forKey: "shake")
    }
}

