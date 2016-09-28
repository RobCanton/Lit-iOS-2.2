//
//  AppState.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift
import CoreLocation
import IngeoSDK


struct AppState: StateType {
    var userState: UserState
    var locations: [Location]
    var cities: [City]
    var activeLocationIndex:Int
    var storyViewIndex:Int
    var viewLocationKey:String = ""
    
    var friends = Tree<String>()
    
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
    
    var friendRequests = [String:FriendRequest]()
    var friendRequestsOut = [String:FriendRequest]()
    
    var unseenRequests = 0
}
