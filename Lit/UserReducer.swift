//
//  UserReducer.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-30.
//  Copyright © 2016 Robert Canton. All rights reserved.
//
import ReSwift

func UserStateReducer(action: Action, state: UserState?) -> UserState {
    var state = state ?? UserState()
    switch action {
    case _ as UserIsAuthenticated:
        let a = action as! UserIsAuthenticated
        state.flow = a.flow
        state.isAuth = true
        if let user = a.user {
            state.uid = user.getUserId()
            state.user = user
        }

        break
    case _ as UserIsUnauthenticated:
        state = UserState()
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
    default:
        break
    }
    
    return state
}