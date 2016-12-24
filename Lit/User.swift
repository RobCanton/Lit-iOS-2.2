//
//  User.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-10.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation

class User:NSObject, NSCoding {
    var uid: String
    var displayName: String
    var name: String?
    var imageURL: String
    var largeImageURL: String?
    var bio: String?
    
    init(uid:String, displayName:String, name:String?, imageURL: String, largeImageURL: String?, bio: String?)
    {
        self.uid           = uid
        self.displayName   = displayName
        self.name          = name
        self.imageURL      = imageURL
        self.largeImageURL = largeImageURL
        self.bio           = bio
    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let uid = decoder.decodeObjectForKey("uid") as! String
        let displayName = decoder.decodeObjectForKey("displayName") as! String
        let name = decoder.decodeObjectForKey("name") as? String
        let imageURL = decoder.decodeObjectForKey("imageURL") as! String
        let largeImageURL = decoder.decodeObjectForKey("largeImageURL") as? String
        let bio = decoder.decodeObjectForKey("bio") as? String

        self.init(uid: uid, displayName: displayName, name: name, imageURL: imageURL, largeImageURL: largeImageURL, bio: bio)

    }

    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(uid, forKey: "uid")
        coder.encodeObject(displayName, forKey: "displayName")
        coder.encodeObject(name, forKey: "name")
        coder.encodeObject(imageURL, forKey: "imageURL")
        coder.encodeObject(largeImageURL, forKey: "largeImageURL")
        coder.encodeObject(bio, forKey: "bio")
    }
    

    
    func getUserId() -> String {
        return uid
    }
    
    func getDisplayName() -> String {
        return displayName
    }
    
    func getName() -> String? {
        return name
    }
    
    func getImageUrl() -> String {
        return imageURL
    }
    
    func setImageURLS(largeImageURL:String, smallImageURL:String) {
        self.largeImageURL = largeImageURL
        self.imageURL = smallImageURL
    }
    
}