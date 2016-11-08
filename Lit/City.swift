//
//  City.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-06.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import CoreLocation

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
