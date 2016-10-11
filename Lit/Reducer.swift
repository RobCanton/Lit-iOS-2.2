//
//  Reducer.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift

struct AppReducer: Reducer {
    
    func handleAction(action: Action, state: AppState?) -> AppState {

        return AppState(
            userState: UserStateReducer(action, state: state?.userState),
            locations:LocationsReducer(action, state: state?.locations),
            cities:CitiesReducer(action, state: state?.cities),
            activeLocationIndex: ActiveLocationIndexReducer(action, state: state?.activeLocationIndex),
            storyViewIndex:StoryViewIndexReducer(action, state: state?.storyViewIndex),
            viewLocationKey: ViewLocationReducer(action, state: state?.viewLocationKey),
            viewUser: ViewUserReducer(action, state: state?.viewUser),
            friends: FriendsReducer(action, state: state?.friends),
            friendRequestsIn: FriendRequestsInReducer(action, state: state?.friendRequestsIn),
            friendRequestsOut: FriendRequestsOutReducer(action, state: state?.friendRequestsOut)
        )
    } 
    
}

func ViewUserReducer(action: Action, state:String?) -> String {
    var state = state ?? ""
    
    switch action {
    case _ as ViewUser:
        let a = action as! ViewUser
        state = a.uid
        break
    case _ as UserViewed:
        state = ""
        break
    default:
        break
    }
    return state
}

func CitiesReducer(action: Action, state:[City]?) -> [City] {
    var state = state ?? []
    
    switch action {
    case _ as CitiesRetrieved:
        let a = action as! CitiesRetrieved
        state = a.cities
        break
    default:
        break
    }
    return state
}

func ActiveLocationIndexReducer(action: Action, state:Int?) -> Int {
    var state = state ?? -1
    
    switch action {
    case _ as ActivateLocation:
        let a = action as! ActivateLocation
        state = a.locationIndex
        break
    default:
        break
    }
    return state
}

func StoryViewIndexReducer(action: Action, state:Int?) -> Int {
    var state = state ?? -1
    
    switch action {
    case _ as ViewStory:
        let a = action as! ViewStory
        state = a.index
        break
    default:
        break
    }
    return state
}

func ViewLocationReducer(action: Action, state:String?) -> String {
    var state = state ?? ""
    switch action {
    case _ as ViewLocationDetail:
        let a = action as! ViewLocationDetail
        state = a.locationKey
        break
    default:
        break
    }
    return state
}