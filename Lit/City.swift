//
//  City.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-06.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import CoreLocation

//
//  City.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-06.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import CoreLocation

class Comment {
    
    private var key:String                    // Key in database
    private var author:String
    private var text:String
    private var date:NSDate

    
    
    init(key:String, author:String, text:String, timestamp:Double)
    {
        self.key          = key
        self.author       = author
        self.text         = text
        self.date    = NSDate(timeIntervalSince1970: timestamp/1000)
    }
    
    /* Getters */
    
    func getKey() -> String
    {
        return key
    }
    
    func getAuthor()-> String
    {
        return author
    }
    
    func getText() -> String
    {
        return text
    }
    
    func getDate() -> NSDate
    {
        return date
    }

}

func < (lhs: Comment, rhs: Comment) -> Bool {
    return lhs.date.compare(rhs.date) == .OrderedAscending
}

func > (lhs: Comment, rhs: Comment) -> Bool {
    return lhs.date.compare(rhs.date) == .OrderedDescending
}

func == (lhs: Comment, rhs: Comment) -> Bool {
    return lhs.date.compare(rhs.date) == .OrderedSame
}


class City {
    
    private var key:String                    // Key in database
    private var name:String
    private var coordinates:CLLocation
    private var country:String
    private var region:String

    
    
    init(key:String, name:String, latitude:Double, longitude:Double, country:String, region:String)
    {
        self.key          = key
        self.name         = name
        self.coordinates  = CLLocation(latitude: latitude, longitude: longitude)
        self.country      = country
        self.region       = region
    }
    
    /* Getters */
    
    func getKey() -> String
    {
        return key
    }
    
    func getName()-> String
    {
        return name
    }
    
    func getCoordinates() -> CLLocation
    {
        return coordinates
    }
    
    func getCountry()-> String
    {
        return country
    }
    
    func getRegion()-> String
    {
        return region
    }
    


}
