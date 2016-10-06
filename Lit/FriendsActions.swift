//
//  FriendStateActions.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import ReSwift

struct AddFriend: Action {
    let uid: String
}

struct RemoveFriend: Action {
    let uid: String
}

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