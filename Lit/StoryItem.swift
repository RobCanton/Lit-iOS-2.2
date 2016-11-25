//
//  StoryItem.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-08.
//  Copyright © 2016 Robert Canton. All rights reserved.
//
import Foundation
import UIKit

protocol ItemDelegate {
    func contentLoaded()
    func authorLoaded()
}

enum ContentType:Int {
    case Image = 1
    case Video = 2
    case Invalid =  0
}

class StoryItem: NSObject, NSCoding {
    
    var key:String                    // Key in database
    var authorId:String
    var locationKey:String
    var downloadUrl:NSURL
    var contentType:ContentType
    var dateCreated: NSDate
    var length: Double

    dynamic var image: UIImage?
    dynamic var filePath: NSURL?
    
    
    var delegate:ItemDelegate?
    
    var isContentLoaded = false
    
    init(key: String, authorId: String, locationKey:String, downloadUrl: NSURL, contentType: ContentType, dateCreated: Double, length: Double)
    {
        
        self.key          = key
        self.authorId     = authorId
        self.locationKey  = locationKey
        self.downloadUrl  = downloadUrl
        self.contentType  = contentType
        self.dateCreated  = NSDate(timeIntervalSince1970: dateCreated/1000)
        self.length       = length

    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let key = decoder.decodeObjectForKey("key") as! String
        let authorId = decoder.decodeObjectForKey("authorId") as! String
        let locationKey = decoder.decodeObjectForKey("imageUrl") as! String
        let downloadUrl = decoder.decodeObjectForKey("downloadUrl") as! NSURL
        let ctInt = decoder.decodeObjectForKey("contentType") as! Int
        let dateCreated = decoder.decodeObjectForKey("dateCreated") as! Double
        let length = decoder.decodeObjectForKey("length") as! Double
        
        var contentType:ContentType = .Invalid
        switch ctInt {
        case 1:
            contentType = .Image
            break
        case 2:
            contentType = .Video
            break
        default:
            break
        }
        
        self.init(key: key, authorId: authorId, locationKey:locationKey, downloadUrl: downloadUrl, contentType: contentType, dateCreated: dateCreated, length: length)
    }
    
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(key, forKey: "key")
        coder.encodeObject(authorId, forKey: "authorId")
        coder.encodeObject(downloadUrl, forKey: "downloadUrl")
        coder.encodeObject(contentType.rawValue, forKey: "contentType")
        coder.encodeObject(dateCreated, forKey: "dateCreated")
        coder.encodeObject(length, forKey: "length")
    }
    
    
    func getKey() -> String {
        return key
    }
    
    func getAuthorId() -> String {
        return authorId
    }
    
    func getLocationKey() -> String {
        return locationKey
    }
    
    func getDownloadUrl() -> NSURL {
        return downloadUrl
    }
    
    func getContentType() -> ContentType? {
        return contentType
    }
    
    func getDateCreated() -> NSDate? {
        return dateCreated
    }
    
    func getLength() -> Double {
        return length
    }
    
    
    func download(completionHandler:(success:Bool)->()) {
        if contentType == .Image && image != nil {
            return completionHandler(success: true)
        }
        
        NSURLSession.sharedSession().dataTaskWithURL(self.downloadUrl, completionHandler:
            { (data, response, error) in
                
                //error
                if error != nil {
                    print(error)
                    return
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    if self.contentType == .Image {
                        self.image = UIImage(data: data!)
                        return completionHandler(success: true)
                    }
//                    else if self.contentType == .Video {
//                        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
//                        self.filePath = documentsURL.URLByAppendingPathComponent("\(self.key).mp4")
//                        
//                        do {
//                            try data!.writeToURL(self.filePath!, atomically: true)
//                            self.delegate?.contentLoaded()
//                            print("Key: \(self.key) | video loaded")
//                            
//                        } catch {
//                            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
//                            print("Error saving file at path: \(self.filePath?.absoluteString) with error: \(error)")
//                        }
//                    }
                })
                
        }).resume()
    }
}