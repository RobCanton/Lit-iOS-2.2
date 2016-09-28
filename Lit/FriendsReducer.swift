//
//  FriendsStateReducer.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift

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
        break
    default:
        break
    }

    return state
}