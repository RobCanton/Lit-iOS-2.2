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
        state.isAuth = true
        state.uid = a.user.getUserId()
        state.user = a.user
        break
    case _ as UserIsUnauthenticated:
        Listeners.stopListeningToAll()
        state = UserState()
        break

    case _ as SetActiveLocation:
        let a = action as! SetActiveLocation
        state.activeLocationKey = a.locationKey
        break
    default:
        break
    }
    
    return state
}