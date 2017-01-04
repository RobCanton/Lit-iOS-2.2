//
//  CounterActions.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift
//


struct UserIsAuthenticated: Action {
    let user: User
}

struct UserIsUnauthenticated: Action {}

struct UpdateUser: Action {
    let user: User
}

struct UpdateFriendRequestsIn: Action {
    let requests:[String:FriendRequest]
    let unseen: Int
}
struct UpdateFriendRequestsOut: Action {
    let requests:[String:FriendRequest]
}


struct UpdateFriends: Action {
    let friends:[String:Friend]
}

struct UpdateProfileImageURL: Action {
    let largeImageURL: String
    let smallImageURL: String
}