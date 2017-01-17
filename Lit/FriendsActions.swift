//
//  FriendStateActions.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import ReSwift


struct AddFriendRequestIn: Action {
    let uid: String
    let seen: Bool
}

struct SeenFriendRequestIn: Action {
    let uid: String
}

struct RemoveFriendRequestIn: Action {
    let uid: String
    let seen: Bool
}

struct AddFriendRequestOut: Action {
    let uid: String
    let seen: Bool
}

struct RemoveFriendRequestOut: Action {
    let uid: String
    let seen: Bool
}

/* Destructive Actions */
struct ClearFriendRequestsIn: Action {}
struct ClearFriendRequestsOut: Action {}

struct AddFollower: Action {
    let uid: String
}

struct RemoveFollower: Action {
    let uid: String
}

struct AddFollowing: Action {
    let uid: String
}

struct RemoveFollowing: Action {
    let uid: String
}

struct ClearSocialState: Action {}