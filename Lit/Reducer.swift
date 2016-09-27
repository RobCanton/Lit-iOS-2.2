//
//  Reducer.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift
import ReSwiftRouter
//

struct AppReducer: Reducer {
    
    func handleAction(action: Action, state: AppState?) -> AppState {

        return AppState(
            userState: UserStateReducer(action, state: state?.userState),
            navigationState: NavigationReducer.handleAction(action, state: state?.navigationState),
            locations:LocationsReducer(action, state: state?.locations),
            cities:CitiesReducer(action, state: state?.cities),
            activeLocationIndex: ActiveLocationIndexReducer(action, state: state?.activeLocationIndex),
            storyViewIndex:StoryViewIndexReducer(action, state: state?.storyViewIndex),
            viewLocationKey: ViewLocationReducer(action, state: state?.viewLocationKey)
        )
    } 
    
}

func UserStateReducer(action: Action, state: UserState?) -> UserState {
    var state = state ?? UserState()
    switch action {
    case _ as UserIsAuthenticated:
        let a = action as! UserIsAuthenticated
        state.isAuth = true
        state.uid = a.uid
        break
    case _ as UserIsUnauthenticated:
        state.isAuth = false
        state.uid = ""
        break
    case _ as UpdateUserLocation:
        let a = action as! UpdateUserLocation
        state.coordinates = a.location
        break
    case _ as SetActiveCity:
        let a = action as! SetActiveCity
        state.activeCity = a.city
        break
    case _ as SetActiveLocation:
        let a = action as! SetActiveLocation
        state.activeLocationKey = a.locationKey
        break
    case _ as Vote:
        let a = action as! Vote
        state.vote = a.state
        break
    case _ as UpdateFriendRequestsIn:
        let a = action as! UpdateFriendRequestsIn
        state.friendRequests = a.requests
        state.unseenRequests = a.unseen
        break
    case _ as UpdateFriendRequestsOut:
        let a = action as! UpdateFriendRequestsOut
        state.friendRequestsOut = a.requests
        break
    case _ as UpdateFriends:
        let a = action as! UpdateFriends
        state.friends = a.friends
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

func LocationsReducer(action: Action, state:[Location]?) -> [Location] {
    var state = state ?? []
    
    switch action {
    case _ as LocationsRetrieved:
        let a = action as! LocationsRetrieved
        state = a.locations
        break
    case _ as LocationStoryLoaded:
        let a = action as! LocationStoryLoaded
        let index = a.locationIndex
        state[index].setStory(a.story)
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