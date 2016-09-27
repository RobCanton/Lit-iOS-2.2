//
//  CounterActions.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift
import ReSwiftRouter
//


struct UserIsAuthenticated: Action {
    let uid: String
}

struct UserIsUnauthenticated: Action {}

struct UpdateFriendRequestsIn: Action {
    let requests:[FriendRequest]
    let unseen: Int
}
struct UpdateFriendRequestsOut: Action {
    let requests:[FriendRequest]
}


struct UpdateFriends: Action {
    let friends:[Friend]
}