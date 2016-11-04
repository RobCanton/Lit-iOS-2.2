//
//  Event.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-01.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class Event {
    
    private var key:String
    private var name:String
    private var date:NSDate
    private var imageUrl:String
    
    
    
    init(key: String, name:String, date:String, imageUrl:String)
    {
        self.key       = key
        self.name      = name
        self.imageUrl  = imageUrl
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        self.date = dateFormatter.dateFromString(date)!
        
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
        return date.timeIntervalSinceNow < 0
    }
}