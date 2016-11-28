//
//  Utilities.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-28.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

// convert an NSDate object to a timestamp string

func convertToTimestamp(date: NSDate) -> String {
    return String(Int64(date.timeIntervalSince1970 * 1000))
}

// Convert the timestamp string to an NSDate object

func convertFromTimestamp(seconds: String) -> NSDate {
    let time = (seconds as NSString).doubleValue/1000.0
    return NSDate(timeIntervalSince1970: NSTimeInterval(time))
}

// format the date using a timestamp

func formatDateTime(timestamp: String) -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateStyle = .ShortStyle
    dateFormatter.timeStyle = .ShortStyle
    let date = convertFromTimestamp(timestamp)
    return dateFormatter.stringFromDate(date)
}


func getLikesString(numLikes:Int) -> String{
    if numLikes == 0 {
        return ""
    } else if numLikes == 1 {
        return "1 like"
    }
    
    return "\(numLikes) likes"
}


func printFonts() {
    let fontFamilyNames = UIFont.familyNames()
    for familyName in fontFamilyNames {
        print("------------------------------")
        print("Font Family Name = [\(familyName)]")
        let names = UIFont.fontNamesForFamilyName(familyName as! String)
        print("Font Names = [\(names)]")
    }
}


func getDateString(date:NSDate) -> String {
    let weekFromDay = NSDate().xDays(7)
    
    if date.timeIntervalSinceDate(weekFromDay) < 0 {
        if NSCalendar.currentCalendar().isDateInToday(date) {
            return "Tonight"
        } else if NSCalendar.currentCalendar().isDateInTomorrow(date) {
            return "Tomorrow"
        } else if NSCalendar.currentCalendar().isDateInYesterday(date) {
            return "Yesterday"
        }
        
        return date.dayOfTheWeek()
    }
    
    let formatter = NSDateFormatter()
    formatter.dateStyle = NSDateFormatterStyle.LongStyle
    formatter.timeStyle = .NoStyle
    
    return formatter.stringFromDate(date)
    
}

func getDateFromString(string:String) -> NSDate {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    return dateFormatter.dateFromString(string)!
}

func downloadImageWithURLString(_url:String, completion: (image:UIImage)->()) {
    
    let url = NSURL(string: _url)
    
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
            
            dispatch_async(dispatch_get_main_queue(), {
                
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: _url)
                }
                
                let image = UIImage(data: data!)
                return completion(image: image!)
            })
            
    }).resume()
}

func loadImageUsingCacheWithURL(_url:String, completion: (image:UIImage)->()) {
    // Check for cached image
    if let cachedImage = imageCache.objectForKey(_url) as? UIImage {
        return completion(image: cachedImage)
    } else {
        downloadImageWithURLString(_url, completion: completion)
    }
}

func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
    
    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
    image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
}

func generateVideoStill(asset:AVAsset, time:CMTime) -> UIImage?{
    do {
        
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        let cgImage = try imgGenerator.copyCGImageAtTime(time, actualTime: nil)
        let image = UIImage(CGImage: cgImage)
        return image
    } catch let error as NSError {
        print("Error generating thumbnail: \(error)")
        return nil
    }
}

func getDistanceString(distance:Double) -> String {
    if distance < 1000 {
        // meters
        let meters = Double(round(1*distance)/1)
        return "\(meters) m"
    } else {
        let km = distance / 1000
        let rounded = Double(round(10*km)/10)
        return "\(rounded) km"
    }
    
}

func clearDirectory(name:String) {
    let fileManager = NSFileManager.defaultManager()
    let documentsURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    let dirPath = documentsURL.URLByAppendingPathComponent("temp")
    do {
        let filePaths = try fileManager.contentsOfDirectoryAtURL(dirPath, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
        for filePath in filePaths {
            try NSFileManager.defaultManager().removeItemAtURL(filePath)
        }
    } catch {
        print("Could not clear temp folder: \(error)")
    }
}
