//
//  AppState.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift
import ReSwiftRouter
import CoreLocation
import IngeoSDK


struct AppState: StateType, HasNavigationState {
    var userState: UserState
    var navigationState: NavigationState
    var locations: [Location]
    var cities: [City]
    var activeLocationIndex:Int
    var storyViewIndex:Int
    var viewLocationKey:String = ""
    
    func printStore() {
        
    }
}

struct UserState {
    var isAuth: Bool = false
    var uid: String = ""
    var coordinates: IGLocation?
    var activeCity: City?
    var activeLocationKey:String=""
    var vote:RatingState = .Selection
}
