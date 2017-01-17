//
//  FriendsStateReducer.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift


func FriendRequestsInReducer(action: Action, state:[String:Bool]?) -> [String:Bool] {
    var state = state ?? [String:Bool]()
    
    switch action {
    case _ as AddFriendRequestIn:
        let a = action as! AddFriendRequestIn
        state[a.uid] = a.seen
        break
    case _ as SeenFriendRequestIn:
        let a = action as! SeenFriendRequestIn
        state[a.uid] = true
        break
    case _ as RemoveFriendRequestIn:
        let a = action as! RemoveFriendRequestIn
        state.removeValueForKey(a.uid)
        break
    case _ as ClearFriendRequestsIn:
        state = [String:Bool]()
        break
    default:
        break
    }
    
    return state
}

func FriendRequestsOutReducer(action: Action, state:[String:Bool]?) -> [String:Bool] {
    var state = state ?? [String:Bool]()
    
    switch action {
    case _ as AddFriendRequestOut:
        let a = action as! AddFriendRequestOut
        state[a.uid] = a.seen
        break
    case _ as RemoveFriendRequestOut:
        let a = action as! RemoveFriendRequestOut
        state.removeValueForKey(a.uid)
        break
    case _ as ClearFriendRequestsIn:
        state = [String:Bool]()
        break
    default:
        break
    }
    
    return state
}