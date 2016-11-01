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
    var imageUrl: String
    var largeImageUrl: String
    var numFriends: Int
    
    init(uid:String, displayName:String, imageUrl: String, largeImageUrl:String, numFriends: Int)
    {
        self.uid           = uid
        self.displayName   = displayName
        self.imageUrl      = imageUrl
        self.largeImageUrl = largeImageUrl
        self.numFriends    = numFriends
    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let uid = decoder.decodeObjectForKey("uid") as! String
        let displayName = decoder.decodeObjectForKey("displayName") as! String
        let imageUrl = decoder.decodeObjectForKey("imageUrl") as! String
        let largeImageUrl = decoder.decodeObjectForKey("largeImageUrl") as! String
        let numFriends = decoder.decodeObjectForKey("numFriends") as! Int
        self.init(uid: uid, displayName: displayName, imageUrl: imageUrl, largeImageUrl: largeImageUrl, numFriends: numFriends)

    }

    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(uid, forKey: "uid")
        coder.encodeObject(displayName, forKey: "displayName")
        coder.encodeObject(imageUrl, forKey: "imageUrl")
        coder.encodeObject(largeImageUrl, forKey: "largeImageUrl")
        coder.encodeObject(numFriends, forKey: "numFriends")
        
    }
    

    
    func getUserId() -> String {
        return uid
    }
    
    func getDisplayName() -> String {
        return displayName
    }
    
    func getImageUrl() -> String {
        return imageUrl
    }
    
    func getLargeImageUrl() -> String {
        return largeImageUrl
    }
    
    func getNumFriends() -> Int{
        return numFriends
    }
    
    func printUser() {
        print("uid: \(uid)")
        print("displayName: \(displayName)")
        print("imageUrl: \(imageUrl)")
    }
    
}