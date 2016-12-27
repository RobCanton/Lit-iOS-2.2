//
//  StoryItem.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-08.
//  Copyright © 2016 Robert Canton. All rights reserved.
//
import Foundation
import UIKit
import AVFoundation

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
    var videoURL:NSURL?
    var contentType:ContentType
    var dateCreated: NSDate
    var length: Double

    dynamic var image: UIImage?
    dynamic var videoFilePath: NSURL?
    dynamic var videoData:NSData?
    
    
    var delegate:ItemDelegate?
    
    init(key: String, authorId: String, locationKey:String, downloadUrl: NSURL, videoURL:NSURL?, contentType: ContentType, dateCreated: Double, length: Double)
    {
        
        self.key          = key
        self.authorId     = authorId
        self.locationKey  = locationKey
        self.downloadUrl  = downloadUrl
        self.videoURL     = videoURL
        self.contentType  = contentType
        self.dateCreated  = NSDate(timeIntervalSince1970: dateCreated/1000)
        self.length       = length

    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let key         = decoder.decodeObjectForKey("key") as! String
        let authorId    = decoder.decodeObjectForKey("authorId") as! String
        let locationKey = decoder.decodeObjectForKey("imageUrl") as! String
        let downloadUrl = decoder.decodeObjectForKey("downloadUrl") as! NSURL
        let ctInt       = decoder.decodeObjectForKey("contentType") as! Int
        let dateCreated = decoder.decodeObjectForKey("dateCreated") as! Double
        let length      = decoder.decodeObjectForKey("length") as! Double
        let videoURL    = decoder.decodeObjectForKey("videoURL") as? NSURL
        
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
        
        self.init(key: key, authorId: authorId, locationKey:locationKey, downloadUrl: downloadUrl, videoURL: videoURL, contentType: contentType, dateCreated: dateCreated, length: length)
    }
    
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(key, forKey: "key")
        coder.encodeObject(authorId, forKey: "authorId")
        coder.encodeObject(downloadUrl, forKey: "downloadUrl")
        coder.encodeObject(contentType.rawValue, forKey: "contentType")
        coder.encodeObject(dateCreated, forKey: "dateCreated")
        coder.encodeObject(length, forKey: "length")
        if videoURL != nil {
            coder.encodeObject(videoURL!, forKey: "videoURL")
        }
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
    
    func getVideoURL() -> NSURL? {
        return videoURL
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
    
    func needsDownload() -> Bool{
        if contentType == .Image {
            if let cachedImage = imageCache.objectForKey(downloadUrl.absoluteString) as? UIImage {
                image = cachedImage
                return false
            }
        }
        
        if contentType == .Video {
            if let _ = loadVideoFromCache(key) {
                return false
            }
        }  
        return true
    }
    
    func download(completionHandler:(success:Bool)->()) {
            
        loadImageUsingCacheWithURL(downloadUrl.absoluteString, completion: { image, fromCache in
            self.image = image
            if self.contentType == .Image { return completionHandler(success: true) }
            
            if self.contentType == .Video {
                
                if let _ = loadVideoFromCache(self.key) {
                    print("Retrieved video from cache")
                    return completionHandler(success: true)
                } else {
                    downloadVideoWithKey(self.key, completion: { data in
                        saveVideoInCache(self.key, data: data)
                        print("Downloaded video and saved to cache")
                        return completionHandler(success: true)
                    })
                }
            }
        })
    }
}