//
//  LocationActions.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import CoreLocation
import Foundation
import ReSwift
import IngeoSDK

struct CitiesRetrieved: Action {
    let cities: [City]
}

struct LocationsRetrieved: Action {
    let locations: [Location]
}

struct SetActiveLocation: Action {
    let locationKey: String
}


struct AddVisitorToLocation: Action {
    let locationIndex:Int
    let uid:String
    let timestamp:Double
}

struct RemoveVisitorFromLocation: Action {
    let locationIndex:Int
    let uid:String
}

struct AddPostToLocation: Action {
    let locationIndex:Int
    let key:String
}

struct RemovePostFromLocation: Action {
    let locationIndex:Int
    let key:String
}


struct SetLocations: Action {
    let locations: [String]
}

/* Destructive Actions */

struct ClearLocations: Action {}
struct ClearCities: Action {}

