//
//  FriendsStateReducer.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift


func isFriend(user:String) -> Bool {
    return mainStore.state.friends.contains(user)
}

func sortUsersArrayByFriends(users:[String]) -> [String] {
    let friends = mainStore.state.friends
    var sortedArray = [String]()

    for user in users {
        if friends.contains(user) {
            sortedArray.insert(user, atIndex: 0)
        } else {
            sortedArray.append(user)
        }
    }
    
    return sortedArray
}

func FriendsReducer(action: Action, state:Tree<String>?) -> Tree<String> {
    var state = state ?? Tree<String>()
    
    switch action {
    case _ as AddFriend:
        let a = action as! AddFriend
        state.insert(a.uid)
        print("Friend Added - \(a.uid)")

        break
    case _ as RemoveFriend:
        let a = action as! RemoveFriend
        state.remove(a.uid)
        print("Friend Removed - \(a.uid)")
        state.forEach({ body in
            print(" * \(body)")
            })
        break
    case _ as ClearFriends:
        state = Tree<String>()
        break
    default:
        break
    }

    return state
}

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