//
//  City.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-06.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import IngeoSDK

class City {
    
    private var key:String                    // Key in database
    private var name:String
    private var coordinates:IGLocation
    private var country:String
    private var region:String

    
    
    init(key:String, name:String, coordinates:IGLocation, country:String, region:String)
    {
        self.key          = key
        self.name         = name
        self.coordinates  = coordinates
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
    
    func getCoordinates() -> IGLocation
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
