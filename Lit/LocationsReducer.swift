//
//  LocationsReducer.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-28.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift

func LocationsReducer(action: Action, state:[Location]?) -> [Location] {
    var state = state ?? [Location]()
    
    switch action {
    case _ as LocationsRetrieved:
        let a = action as! LocationsRetrieved
        state = a.locations
        break
    case _ as AddVisitorToLocation:
        let a = action as! AddVisitorToLocation
        state[a.locationIndex].addVisitor(a.uid)
        break
    case _ as RemoveVisitorFromLocation:
        let a = action as! RemoveVisitorFromLocation
        state[a.locationIndex].removeVisitor(a.uid)
    case _ as AddPostToLocation:
        let a = action as! AddPostToLocation
        state[a.locationIndex].addPost(a.key)
        break
    case _ as RemovePostFromLocation:
        let a = action as! RemovePostFromLocation
        state[a.locationIndex].removePost(a.key)
        break
    case _ as ClearLocations:
        state = [Location]()
    default:
        break
    }
    return state
}

func NearbyLocationsReducer(action: Action, state:[String]?) -> [String] {
    var state = state ?? [String]()
    
    switch action {
    case _ as SetLocations:
        let a = action as! SetLocations
        state = a.locations
        break
    case _ as ClearLocations:
        state = [String]()
        break
    default:
        break
    }
    return state
}

func CitiesReducer(action: Action, state:[City]?) -> [City] {
    var state = state ?? [City]()
    
    switch action {
    case _ as CitiesRetrieved:
        let a = action as! CitiesRetrieved
        state = a.cities
        break
    case _ as ClearCities:
        state = [City]()
        break
    default:
        break
    }
    return state
}