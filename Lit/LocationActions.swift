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

struct ActivateLocation: Action {
    let locationIndex: Int
}

struct LocationStoryLoaded: Action {
    let locationIndex: Int
    let story: [StoryItem]
}

struct ViewStory: Action {
    let index: Int
}


struct ViewLocationDetail: Action {
    let locationKey: String
}

struct UpdateUserLocation: Action {
    let location: IGLocation
}

struct SetActiveCity: Action {
    let city:City
}

struct SetActiveLocation: Action {
    let locationKey: String
}

struct Vote: Action {
    let state:RatingState
}

struct AddVisitorToLocation: Action {
    let locationIndex:Int
    let uid:String
}

struct RemoveVisitorFromLocation: Action {
    let locationIndex:Int
    let uid:String
}
