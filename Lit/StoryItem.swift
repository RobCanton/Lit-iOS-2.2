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

enum ContentType {
    case Image, Video, Invalid
}

class StoryItem: NSObject {
    
    private var key:String                    // Key in database
    private var authorId:String
    private var locationKey:String
    private var downloadUrl:NSURL?
    private var contentType:ContentType
    private var dateCreated: NSDate?
    private var length: Double?
    dynamic var image: UIImage?
    dynamic var filePath: NSURL?
    private var author:User?
    var delegate:ItemDelegate?
    
    var isContentLoaded = false
    
    init(key: String, authorId: String, locationKey:String, downloadUrl: String, contentType: ContentType, dateCreated: Double, length: Double)
    {
        
        self.key          = key
        self.authorId     = authorId
        self.locationKey     = locationKey
        self.downloadUrl  = NSURL(string: downloadUrl)
        self.contentType  = contentType
        self.dateCreated  = NSDate(timeIntervalSince1970: dateCreated/1000)
        self.length       = length
    
        
        super.init()
    }
    
    
    func getKey() -> String {
        return key
    }
    
    func getAuthorId() -> String {
        return authorId
    }
    
    func getLocationKey() -> String {
        return authorId
    }
    
    func getAuthor() -> User? {
        return author
    }
    
    func getDownloadUrl() -> NSURL? {
        return downloadUrl
    }
    
    func getContentType() -> ContentType? {
        return contentType
    }
    
    func getDateCreated() -> NSDate? {
        return dateCreated
    }
    
    func getLength() -> Double? {
        return length
    }
    
    func initiateDownload() {
        loadAuthor()
        NSURLSession.sharedSession().dataTaskWithURL(self.downloadUrl!, completionHandler:
            { (data, response, error) in
                
                //error
                if error != nil {
                    print(error)
                    return
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    if self.contentType == .Image {
                        self.image = UIImage(data: data!)
                        
                        self.delegate?.contentLoaded()
                        print("Key: \(self.key) | image loaded")
                    }
                    else if self.contentType == .Video {
                        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                        self.filePath = documentsURL.URLByAppendingPathComponent("\(self.key).mp4")
                        
                        do {
                            try data!.writeToURL(self.filePath!, atomically: true)
                            self.delegate?.contentLoaded()
                            print("Key: \(self.key) | video loaded")
                            
                        } catch {
                            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                            print("Error saving file at path: \(self.filePath?.absoluteString) with error: \(error)")
                        }
                    }
                })
                
        }).resume()
    }
    
    func loadAuthor() {
        print("Fetching author: " + authorId)
        FirebaseService.getUser(authorId, completionHandler: { user in
            print("Fetched author: \(user.getUserId()) : \(user.getDisplayName())")
            self.author = user
            self.delegate?.authorLoaded()
        })
    }
    
}