//
//  Extensions.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-28.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

let imageCache = NSCache()

extension UIImageView {
    
    func loadImageUsingCacheWithURLString(_url:String, completion: (result: Bool)->()) {
        
        if self.image != nil {
            if self.restorationIdentifier == _url {
                return completion(result: false)
            } else {
                self.image = nil
            }
        }

        // Check for cached image
        if let cachedImage = imageCache.objectForKey(_url) as? UIImage {
            self.image = cachedImage
            //print("From cache: \(_url)")
            self.restorationIdentifier = _url
            return completion(result: true)
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
                    //print("Downloaded image: \(_url)")
                    self.restorationIdentifier = _url
                    return completion(result: true)
                })
                
        }).resume()
    }
    
    func loadImageUsingFileWithURLString(location:Location, completion: (result: Bool)->()) {
        
        if let file = location.imageOnDiskURL {
            print("FROM FILE: \(file)")
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
                        let fileURL = documentsURL.URLByAppendingPathComponent("location_images").URLByAppendingPathComponent("\(location.getKey()).jpg")
                        if let jpgData = UIImageJPEGRepresentation(image, 1.0) {
                            jpgData.writeToURL(fileURL, atomically: true)
                            location.imageOnDiskURL = fileURL
                            print("WRITTEN TO FILE: \(location.imageOnDiskURL!)")
                            
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
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
    func xDays(days:Int) -> NSDate {

        return NSCalendar.currentCalendar().dateByAddingUnit( .Day, value: days, toDate: self, options: NSCalendarOptions.MatchFirst)!
    }
    
    func dayOfTheWeek() -> String! {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.stringFromDate(self)
    }
    
    
    func timeStringSinceNow() -> String
    {
        let calendar = NSCalendar.currentCalendar()
        
        let components = calendar.components([.Day, .Hour, .Minute, .Second], fromDate: self, toDate: NSDate(), options: [])
        
        if components.day >= 365 {
            return "\(components.day / 365)y"
        }
        
        if components.day >= 7 {
            return "\(components.day / 7)w"
        }
        
        if components.day > 0 {
            return "\(components.day)d"
        }
        else if components.hour > 0 {
            return "\(components.hour)h"
        }
        else if components.minute > 0 {
            return "\(components.minute)m"
        }
        return "Now"
        //return "\(components.second)s"
    }
    
    func timeStringSinceNowWithAgo() -> String
    {
        let calendar = NSCalendar.currentCalendar()
        
        let components = calendar.components([.Day, .Hour, .Minute, .Second], fromDate: self, toDate: NSDate(), options: [])
        
        if components.day >= 365 {
            return "\(components.day / 365)y ago"
        }
        
        if components.day >= 7 {
            return "\(components.day / 7)w ago"
        }
        
        if components.day > 0 {
            return "\(components.day)d ago"
        }
        else if components.hour > 0 {
            return "\(components.hour)h ago"
        }
        else if components.minute > 0 {
            return "\(components.minute)m ago"
        }
        return "Now"
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
    
    
    func styleProfileBlockText(count:Int, text:String, color:UIColor, color2:UIColor) {
        self.numberOfLines = 2
        self.textAlignment = .Center
    

        let str = "\(count)\n\(text)"
        let font = UIFont(name: "AvenirNext-Regular", size: 12)
        
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : font!,
            NSForegroundColorAttributeName : color,
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        
        let countStr = "\(count)"
        if let range = str.rangeOfString(countStr) {
            let index = str.startIndex.distanceTo(range.startIndex)
            let a: [String: AnyObject] = [
                NSFontAttributeName : UIFont(name: "AvenirNext-Medium", size: 16)!,
                NSForegroundColorAttributeName : color2
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

extension UINavigationController {
    
    func pushViewController(viewController: UIViewController,
                            animated: Bool, completion: Void -> Void) {
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        pushViewController(viewController, animated: animated)
        CATransaction.commit()
    }
    
    func popViewController(animated: Bool, completion: Void -> Void) {
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        popViewControllerAnimated(animated)
        CATransaction.commit()
    }
    

    
    
}

extension UIView {
    
    func pb_takeSnapshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.mainScreen().scale)
        
        drawViewHierarchyInRect(self.bounds, afterScreenUpdates: true)
        
        // old style: layer.renderInContext(UIGraphicsGetCurrentContext())
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIButton {
    private func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func setBackgroundColor(color: UIColor, forUIControlState state: UIControlState) {
        self.setBackgroundImage(imageWithColor(color), forState: state)
    }
}

extension UIImage {
    func grayScaleImage() -> UIImage {
        let imageRect = CGRectMake(0, 0, self.size.width, self.size.height);
        let colorSpace = CGColorSpaceCreateDeviceGray();
        
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        let context = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpace, .allZeros);
        CGContextDrawImage(context, imageRect, self.CGImage!);
        
        let imageRef = CGBitmapContextCreateImage(context);
        let newImage = UIImage(CGImage: imageRef!)
        return newImage
    }
}

public extension UILabel {
    public class func size(withText text: String, forWidth width: CGFloat) -> CGSize {
        let measurementLabel = UILabel()
        measurementLabel.font = UIFont(name: "AvenirNext-Regular", size: 14.0)
        measurementLabel.text = text
        measurementLabel.numberOfLines = 0
        measurementLabel.lineBreakMode = .ByWordWrapping
        measurementLabel.translatesAutoresizingMaskIntoConstraints = false
        
        measurementLabel.widthAnchor.constraintEqualToConstant(width).active = true
        return measurementLabel.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
    }
}