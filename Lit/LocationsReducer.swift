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
    case _ as SetVisitorsForLocation:
        let a = action as! SetVisitorsForLocation
        state[a.locationIndex].visitors = a.visitors
        break
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

func ActiveLocationsReducer(action: Action, state:[Int]?) -> [Int] {
    var state = state ?? [Int]()
    
    switch action {
    case _ as SetActiveLocations:
        let a = action as! SetActiveLocations
        state = a.indexes
    case _ as ClearActiveLocations:
        state = [Int]()
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