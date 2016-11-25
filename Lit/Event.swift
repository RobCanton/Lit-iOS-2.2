//
//  Event.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-01.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class Event: NSObject, NSCoding {
    
    private var key:String
    private var name:String
    private var date:NSDate
    private var imageUrl:String
    
    
    
    init(key: String, name:String, date:NSDate, imageUrl:String)
    {
        self.key       = key
        self.name      = name
        self.imageUrl  = imageUrl
        self.date = date
    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let key = decoder.decodeObjectForKey("key") as! String
        let name = decoder.decodeObjectForKey("name") as! String
        let date = decoder.decodeObjectForKey("date") as! NSDate
        let imageUrl = decoder.decodeObjectForKey("imageUrl") as! String
        self.init(key:key, name:name, date:date, imageUrl: imageUrl)
        
    }
    
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(key, forKey: "key")
        coder.encodeObject(name, forKey: "name")
        coder.encodeObject(date, forKey: "date")
        coder.encodeObject(imageUrl, forKey: "imageUrl")
    }
    
    func getKey() -> String {
        return key
    }
    
    func getName() -> String {
        return name
    }
    
    func getDate() -> NSDate {
        return date
    }
    
    func getImageUrl() -> String {
        return imageUrl
    }
    
    func hasPassed() -> Bool {
        return date.timeIntervalSinceNow < -86399999
        
    }
}